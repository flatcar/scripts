# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/scons/scons-2.0.1.ebuild,v 1.10 2011/11/21 23:02:25 vapier Exp $

EAPI="3"
PYTHON_DEPEND="2"
PYTHON_USE_WITH="threads"

inherit distutils eutils

DESCRIPTION="Extensible Python-based build utility"
HOMEPAGE="http://www.scons.org/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz
	doc? (
		http://www.scons.org/doc/${PV}/PDF/${PN}-user.pdf -> ${P}-user.pdf
		http://www.scons.org/doc/${PV}/HTML/${PN}-user.html -> ${P}-user.html
	)"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE="doc"

DEPEND=""
RDEPEND=""

DOCS="CHANGES.txt RELEASE.txt"

pkg_setup() {
	python_set_active_version 2
	python_pkg_setup
}

src_prepare() {
	distutils_src_prepare
	epatch "${FILESDIR}/scons-1.2.0-popen.patch"
}

src_install () {
	distutils_src_install
	python_convert_shebangs -r 2 "${ED}"

	# Move man pages from /usr/man to /usr/share/man
	dodir /usr/share
	mv "${ED}usr/man" "${ED}usr/share"

	if use doc; then
		insinto /usr/share/doc/${PF}
		doins "${DISTDIR}"/${P}-user.{pdf,html}
	fi
}

pkg_postinst() {
	python_mod_optimize /usr/$(get_libdir)/${P}
}

pkg_postrm() {
	python_mod_cleanup /usr/$(get_libdir)/${P}
}
