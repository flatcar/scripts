# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libmba/libmba-0.9.1-r1.ebuild,v 1.3 2011/12/18 19:48:09 phajdan.jr Exp $

EAPI="2"

inherit eutils multilib toolchain-funcs

DESCRIPTION="A library of generic C modules."
HOMEPAGE="http://www.ioplex.com/~miallen/libmba/"
SRC_URI="http://www.ioplex.com/~miallen/libmba/dl/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="static-libs"

pkg_setup(){
	use static-libs && export STATIC="1"
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-qa.patch
	tc-export CC
	sed -i -e "s:gcc:${CC}:g" mktool.c || die
	sed -i -e "s:\$(prefix)/lib:\$(prefix)/$(get_libdir):" Makefile || die
}

src_install() {
	emake DESTDIR="${D}" install || die

	dodoc README.txt docs/*.txt || die
	dohtml -r docs/*.html docs/www/* docs/ref || die

	insinto /usr/share/doc/${PF}/examples
	doins examples/* || die
}
