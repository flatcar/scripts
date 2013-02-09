# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/aften/aften-0.0.8.ebuild,v 1.4 2008/06/22 15:13:14 maekke Exp $

inherit eutils cmake-utils

DESCRIPTION="An A/52 (AC-3) audio encoder"
HOMEPAGE="http://aften.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="LGPL-2.1 BSD"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE="cxx"
DEPEND=""

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}/${P}-multilib.patch"
	epatch "${FILESDIR}/${P}-ppc.patch"
}

src_compile() {
	local mycmakeargs="-DSHARED=1"
	use cxx && mycmakeargs="${mycmakeargs} -DBINDINGS_CXX=1"
	cmake-utils_src_compile
}

src_install() {
	cmake-utils_src_install
	dodoc README Changelog
	# File collision with media-sound/wavbreaker, upstream informed
	mv "${D}/usr/bin/wavinfo" "${D}/usr/bin/wavinfo-aften"
}
