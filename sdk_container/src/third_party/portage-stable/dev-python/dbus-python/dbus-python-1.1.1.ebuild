# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/dbus-python/dbus-python-1.1.1.ebuild,v 1.7 2012/10/14 15:00:19 armin76 Exp $

EAPI=4

PYTHON_DEPEND="2:2.6 3:3.2"
SUPPORT_PYTHON_ABIS=1
RESTRICT_PYTHON_ABIS="2.5 3.1 *-jython 2.7-pypy-*"
PYTHON_EXPORT_PHASE_FUNCTIONS=1

inherit python

DESCRIPTION="Python bindings for the D-Bus messagebus"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/DBusBindings http://dbus.freedesktop.org/doc/dbus-python/"
SRC_URI="http://dbus.freedesktop.org/releases/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux"
IUSE="doc examples test"

RDEPEND=">=dev-libs/dbus-glib-0.100
	>=sys-apps/dbus-1.6"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( =dev-python/epydoc-3* )
	test? (
		dev-python/pygobject:2
		dev-python/pygobject:3
		)"

src_prepare() {
	>py-compile
	python_src_prepare
}

src_configure() {
	configuration() {
		econf \
			--docdir="${EPREFIX}"/usr/share/doc/${PF} \
			--disable-html-docs \
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
			nonfatal dohtml -r api/*
		}
		python_execute_function -f -q -s install_documentation
	fi

	if use examples; then
		insinto /usr/share/doc/${PF}
		doins -r examples
	fi

	python_clean_installation_image
}

pkg_postinst() {
	python_mod_optimize dbus
}

pkg_postrm() {
	python_mod_cleanup dbus
}
