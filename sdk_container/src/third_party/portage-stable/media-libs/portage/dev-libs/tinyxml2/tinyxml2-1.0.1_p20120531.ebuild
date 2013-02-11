# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/tinyxml2/tinyxml2-1.0.1_p20120531.ebuild,v 1.5 2012/09/20 12:39:00 radhermit Exp $

EAPI="4"
CMAKE_MIN_VERSION="2.8.5"

inherit cmake-utils

DESCRIPTION="A simple, small, efficient, C++ XML parser"
HOMEPAGE="http://www.grinninglizard.com/tinyxml2/"
SRC_URI="http://dev.gentoo.org/~radhermit/distfiles/${P}.tar.bz2"

LICENSE="ZLIB"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="static-libs test"

PATCHES=(
	"${FILESDIR}"/${P}-test.patch
	"${FILESDIR}"/${P}-test-return-status.patch
)

src_configure() {
	local mycmakeargs=(
		$(cmake-utils_use_build static-libs STATIC_LIBS)
		$(cmake-utils_use_build test TEST)
	)
	cmake-utils_src_configure
}

src_test() {
	cmake-utils_src_test
	./test || die "Tests failed"
}
