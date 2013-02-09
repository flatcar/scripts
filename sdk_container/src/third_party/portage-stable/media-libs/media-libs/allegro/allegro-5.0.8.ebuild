# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/allegro/allegro-5.0.8.ebuild,v 1.1 2013/01/05 05:27:21 mr_bones_ Exp $

EAPI=5
inherit cmake-utils

DESCRIPTION="A game programming library"
HOMEPAGE="http://alleg.sourceforge.net/"
SRC_URI="mirror://sourceforge/alleg/${P}.tar.gz"

LICENSE="BSD ZLIB"
SLOT="5"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86"
IUSE="alsa dumb flac gtk jpeg openal oss physfs png pulseaudio test truetype vorbis X xinerama"

RDEPEND="alsa? ( media-libs/alsa-lib )
	dumb? ( media-libs/dumb )
	flac? ( media-libs/flac )
	jpeg? ( virtual/jpeg )
	openal? ( media-libs/openal )
	physfs? ( dev-games/physfs )
	png? ( >=media-libs/libpng-1.4 )
	pulseaudio? ( >=media-sound/pulseaudio-0.9.15 )
	truetype? ( >=media-libs/freetype-2 )
	vorbis? ( media-libs/libvorbis )
	x11-libs/libXcursor
	x11-libs/libXxf86vm
	x11-libs/libXrandr
	x11-libs/libX11
	gtk? ( x11-libs/gtk+:2 )
	virtual/opengl
	virtual/glu
	xinerama? ( x11-libs/libXinerama )"

DEPEND="${RDEPEND}
	virtual/pkgconfig
	x11-proto/xextproto
	x11-proto/xf86vidmodeproto
	x11-proto/xproto"

PATCHES=( "${FILESDIR}"/${PN}-5.0.4-underlink.patch )

src_configure() {
	local mycmakeargs=(
		$(cmake-utils_use_want alsa)
		-DWANT_DEMO=OFF
		-DWANT_EXAMPLES=OFF
		$(cmake-utils_use_want flac)
		$(cmake-utils_use_want jpeg IMAGE_JPG)
		$(cmake-utils_use_want png IMAGE_PNG)
		$(cmake-utils_use_want dumb MODAUDIO)
		$(cmake-utils_use_want openal)
		$(cmake-utils_use_want oss)
		$(cmake-utils_use_want physfs)
		$(cmake-utils_use_want pulseaudio)
		$(cmake-utils_use_want test TESTS)
		$(cmake-utils_use_want truetype TTF)
		$(cmake-utils_use_want vorbis)
		$(cmake-utils_use_want gtk NATIVE_DIALOG)
		$(cmake-utils_use_want X opengl)
		$(cmake-utils_use_want xinerama X11_XINERAMA)
	)

	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	nonfatal dodoc CHANGES-5.0.txt
	nonfatal dohtml -r docs/html/refman/*
	nonfatal doman docs/man/*.3
}
