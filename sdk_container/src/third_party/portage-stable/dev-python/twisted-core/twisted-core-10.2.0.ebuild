# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/twisted-core/twisted-core-10.2.0.ebuild,v 1.1 2013/08/03 09:34:50 mgorny Exp $

EAPI="3"
PYTHON_DEPEND="2"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.* *-jython *-pypy-*"
MY_PACKAGE="Core"

inherit eutils twisted versionator

DESCRIPTION="An asynchronous networking framework written in Python"
HOMEPAGE="http://www.twistedmatrix.com/ http://pypi.python.org/pypi/Twisted"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~ia64-hpux ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="crypt gtk serial"

DEPEND=">=net-zope/zope-interface-3.0.1
	crypt? ( >=dev-python/pyopenssl-0.5.1 )
	gtk? ( >=dev-python/pygtk-1.99 )
	serial? ( dev-python/pyserial )"
RDEPEND="${DEPEND}
	!dev-python/twisted"

DOCS="CREDITS NEWS README"

src_prepare(){
	distutils_src_prepare

	# Give a load-sensitive test a better chance of succeeding.
	epatch "${FILESDIR}/${PN}-2.1.0-echo-less.patch"

	# Pass valid arguments to "head" in the zsh completion function.
	epatch "${FILESDIR}/${PN}-2.1.0-zsh-head.patch"

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
		local return_status="0"
		"$(PYTHON)" setup.py build -b "build-${PYTHON_ABI}" install --root="${T}/tests" --no-compile || die "Installation of tests failed with $(python_get_implementation) $(python_get_version)"

		pushd "${T}/tests${EPREFIX}$(python_get_sitedir)" > /dev/null || die

		# Skip broken tests.
		sed -e "s/test_buildAllTarballs/_&/" -i twisted/python/test/test_release.py || die "sed failed"

		# Prevent it from pulling in plugins from already installed twisted packages.
		rm -f twisted/plugins/__init__.py

		# An empty file doesn't work because the tests check for doc strings in all packages.
		echo "'''plugins stub'''" > twisted/plugins/__init__.py || die

		if ! PYTHONPATH="." "${T}/tests${EPREFIX}/usr/bin/trial" twisted; then
			if [[ -n "${TWISTED_DEBUG_TESTS}" ]]; then
				die "Tests failed with $(python_get_implementation) $(python_get_version)"
			else
				return_status="1"
			fi
		fi

		popd > /dev/null || die
		rm -fr "${T}/tests"
		return "${return_status}"
	}
	python_execute_function testing
}

src_install() {
	distutils_src_install

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

	# zsh completion
	insinto /usr/share/zsh/site-functions
	doins twisted/python/_twisted_zsh_stub
}
