# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/dbus-python/dbus-python-0.84.0.ebuild,v 1.8 2011/11/27 19:07:37 armin76 Exp $

EAPI="3"
PYTHON_DEPEND="2"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.* *-jython *-pypy-*"
PYTHON_TESTS_RESTRICTED_ABIS="2.4 2.5"
PYTHON_EXPORT_PHASE_FUNCTIONS="1"

inherit eutils python

DESCRIPTION="Python bindings for the D-Bus messagebus"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/DBusBindings http://dbus.freedesktop.org/doc/dbus-python/"
SRC_URI="http://dbus.freedesktop.org/releases/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ~ppc ~ppc64 sh sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux"
IUSE="doc examples test"

RDEPEND=">=dev-libs/dbus-glib-0.88
	>=sys-apps/dbus-1.4.1"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	doc? ( =dev-python/epydoc-3* )
	test? ( dev-python/pygobject:2 )"

src_prepare() {
	# Disable compiling of .pyc files.
	mv py-compile py-compile.orig
	ln -s $(type -P true) py-compile

	# Workaround testsuite issues
	epatch "${FILESDIR}/${PN}-0.83.1-workaround-broken-test.patch"

	python_src_prepare
}

src_configure() {
	configuration() {
		econf \
			--docdir="${EPREFIX}/usr/share/doc/${PF}" \
			$(use_enable doc api-docs)
	}
	python_execute_function -s configuration
}

src_test() {
	unset DBUS_SESSION_BUS_ADDRESS
	python_src_test
}

src_install() {
	python_src_install

	if use doc; then
		install_documentation() {
			dohtml api/* || return 1
		}
		python_execute_function -f -q -s install_documentation
	fi

	if use examples; then
		insinto /usr/share/doc/${PF}/
		doins -r examples || die
	fi

	python_clean_installation_image
}

pkg_postinst() {
	python_mod_optimize dbus dbus_bindings.py
}

pkg_postrm() {
	python_mod_cleanup dbus dbus_bindings.py
}
