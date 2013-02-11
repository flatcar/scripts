# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/chmlib/chmlib-0.40-r1.ebuild,v 1.8 2011/09/29 02:09:38 dirtyepic Exp $

EAPI="3"

inherit autotools-utils

DESCRIPTION="Library for MS CHM (compressed html) file format"
HOMEPAGE="http://www.jedrea.com/chmlib/"
SRC_URI="http://www.jedrea.com/${PN}/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 hppa ~ia64 ppc ppc64 x86"
IUSE="+examples static-libs"

DOCS=(AUTHORS NEWS README)
PATCHES=(
	"${FILESDIR}"/${PN}-0.39-stdtypes.patch
	"${FILESDIR}"/${P}-headers.patch
)

src_configure() {
	myeconfargs=($(use_enable examples))
	autotools-utils_src_configure
}
