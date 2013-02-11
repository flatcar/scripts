# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libbulletml/libbulletml-0.0.6.ebuild,v 1.10 2012/06/07 17:29:16 mr_bones_ Exp $

EAPI=2
inherit eutils

DESCRIPTION="A Library of Bullet Markup Language"
HOMEPAGE="http://shinh.skr.jp/libbulletml/index_en.html"
SRC_URI="http://shinh.skr.jp/libbulletml/${P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE=""

DEPEND="dev-libs/boost"

S=${WORKDIR}/${PN#lib}/src

src_prepare() {
	epatch "${FILESDIR}"/${P}-gcc43.patch \
		"${FILESDIR}"/${P}-gcc46.patch
	rm -r boost || die "remove of local boost failed"
}

src_compile() {
	emake CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" || die
}

src_install() {
	dolib.a libbulletml.a || die

	insinto /usr/include/bulletml
	doins *.h || die

	insinto /usr/include/bulletml/tinyxml
	doins tinyxml/tinyxml.h || die

	insinto /usr/include/bulletml/ygg
	doins ygg/ygg.h || die

	dodoc ../README*
}
