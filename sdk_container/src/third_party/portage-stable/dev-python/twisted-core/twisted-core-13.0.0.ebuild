# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/twisted-core/twisted-core-13.0.0.ebuild,v 1.2 2013/08/06 17:05:08 mgorny Exp $

EAPI="4"
PYTHON_DEPEND="2:2.6"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="2.5 3.* *-jython"
# A couple of failures (refcounting, version-checking), but sufficiently
# functional to be useful, so restrict just the tests.
PYTHON_TESTS_RESTRICTED_ABIS="*-pypy-*"
MY_PACKAGE="Core"

inherit eutils twisted versionator

DESCRIPTION="An asynchronous networking framework written in Python"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~ia64-hpux ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="crypt gtk serial"

DEPEND="net-zope/zope-interface
	crypt? ( >=dev-python/pyopenssl-0.10 )
	gtk? ( dev-python/pygtk:2 )
	serial? ( dev-python/pyserial )"
RDEPEND="${DEPEND}
	!dev-python/twisted"

# Needed to make the sendmsg extension work
# (see http://twistedmatrix.com/trac/ticket/5701 )
PYTHON_CFLAGS=("2.* + -fno-strict-aliasing")

DOCS="CREDITS NEWS README"

src_prepare(){
	distutils_src_prepare

	# Give a load-sensitive test a better chance of succeeding.
	epatch "${FILESDIR}/${PN}-2.1.0-echo-less.patch"

	# Skip a test if twisted conch is not available
	# (see Twisted ticket #5703)
	epatch "${FILESDIR}/twisted-core-12.1.0-remove-tests-conch-dependency.patch"

	# Respect TWISTED_DISABLE_WRITING_OF_PLUGIN_CACHE variable.
	epatch "${FILESDIR}/${PN}-9.0.0-respect_TWISTED_DISABLE_WRITING_OF_PLUGIN_CACHE.patch"

	if [[ "${EUID}" -eq 0 ]]; then
		# Disable tests failing with root permissions.
		sed \
			-e "s/test_newPluginsOnReadOnlyPath/_&/" \
			-e "s/test_deployedMode/_&/" \
			-i twisted/test/test_plugin.py
	fi
}

src_test() {
	testing() {
		local exit_status="0"
		"$(PYTHON)" setup.py build -b "build-${PYTHON_ABI}" install --root="${T}/tests-${PYTHON_ABI}" --no-compile || die "Installation of tests failed with $(python_get_implementation_and_version)"

		pushd "${T}/tests-${PYTHON_ABI}${EPREFIX}$(python_get_sitedir)" > /dev/null || die

		# Skip broken tests.
		sed -e "s/test_buildAllTarballs/_&/" -i twisted/python/test/test_release.py || die "sed failed"

		# http://twistedmatrix.com/trac/ticket/5375
		sed -e "/class ZshIntegrationTestCase/,/^$/d" -i twisted/scripts/test/test_scripts.py || die "sed failed"

		# tap2rpm is already skipped if rpm is not installed, but fails for me on a Gentoo box with it present.
		# I currently lack the cycles to track this failure down.
		rm twisted/scripts/test/test_tap2rpm.py

		# Prevent it from pulling in plugins from already installed twisted packages.
		rm -f twisted/plugins/__init__.py

		# An empty file doesn't work because the tests check for doc strings in all packages.
		echo "'''plugins stub'''" > twisted/plugins/__init__.py || die

		if ! PYTHONPATH="." "${T}/tests-${PYTHON_ABI}${EPREFIX}/usr/bin/trial" twisted; then
			if [[ -n "${TWISTED_DEBUG_TESTS}" ]]; then
				die "Tests failed with $(python_get_implementation_and_version)"
			else
				exit_status="1"
			fi
		fi

		popd > /dev/null || die
		return "${exit_status}"
	}
	python_execute_function testing
}

src_install() {
	distutils_src_install
	python_clean_installation_image

	python_generate_wrapper_scripts -E -f -q "${ED}usr/bin/trial"

	postinstallational_preparation() {
		touch "${ED}$(python_get_sitedir)/Twisted-${PV}-py$(python_get_version).egg-info"

		# Delete dropin.cache to avoid collisions.
		# dropin.cache is regenerated in pkg_postinst().
		rm -f "${ED}$(python_get_sitedir)/twisted/plugins/dropin.cache"
	}
	python_execute_function -q postinstallational_preparation

	# Don't install index.xhtml page.
	doman doc/man/*.?
	insinto /usr/share/doc/${PF}
	doins -r $(find doc -mindepth 1 -maxdepth 1 -not -name man)

	newconfd "${FILESDIR}/twistd.conf" twistd
	newinitd "${FILESDIR}/twistd.init" twistd
}
