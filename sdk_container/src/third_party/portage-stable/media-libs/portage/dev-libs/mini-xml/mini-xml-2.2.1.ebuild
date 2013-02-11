# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/mini-xml/mini-xml-2.2.1.ebuild,v 1.4 2012/07/18 11:09:42 jlec Exp $

EAPI=4

inherit eutils multilib

MY_P=${P/mini-xml/mxml}

DESCRIPTION="Small XML parsing library to read XML and XML-like data files"
HOMEPAGE="http://www.easysw.com/~mike/mxml"
SRC_URI="mirror://easysw/mxml/${PV}/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE="debug doc static-libs"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	epatch "${FILESDIR}"/${P}-nostrip-flags.patch
}

src_configure() {
	econf \
		--enable-shared \
		--libdir="/usr/$(get_libdir)" \
		--with-docdir="${EPREFIX}"/usr/share/doc/${PF} \
		$(use_enable debug)
}

src_test() {
	emake testmxml
}

src_install() {
	emake DSTROOT="${D}" install

	if ! use static-libs; then
		rm -vf "${ED}"/usr/$(get_libdir)/libmxml.a || die
	fi

	use doc && dohtml doc/*
}
