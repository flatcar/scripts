# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/liblastfm/liblastfm-1.0.2.ebuild,v 1.1 2012/09/01 17:47:39 scarabeus Exp $

EAPI=4

QT_MINIMAL="4.8.0"
inherit cmake-utils

DESCRIPTION="Collection of libraries to integrate Last.fm services"
HOMEPAGE="http://github.com/eartle/liblastfm"
SRC_URI="http://cdn.last.fm/client/${P}.tar.gz"

LICENSE="GPL-3"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86"
SLOT="0"
IUSE="fingerprint test"

COMMON_DEPEND="
	>=x11-libs/qt-core-${QT_MINIMAL}:4
	>=x11-libs/qt-dbus-${QT_MINIMAL}:4
	fingerprint? (
		media-libs/libsamplerate
		sci-libs/fftw:3.0
		>=x11-libs/qt-sql-${QT_MINIMAL}:4
	)
"
DEPEND="${COMMON_DEPEND}
	test? ( >=x11-libs/qt-test-${QT_MINIMAL}:4 )
"
RDEPEND="${COMMON_DEPEND}
	!<media-libs/lastfmlib-0.4.0
"

# 1 of 2 is failing, last checked 2012-06-22 / version 1.0.1
RESTRICT="test"

src_configure() {
	# demos not working
	local mycmakeargs=(
		-DBUILD_DEMOS=OFF
		$(cmake-utils_use_build fingerprint)
		$(cmake-utils_use_build test TESTS)
	)

	cmake-utils_src_configure
}
