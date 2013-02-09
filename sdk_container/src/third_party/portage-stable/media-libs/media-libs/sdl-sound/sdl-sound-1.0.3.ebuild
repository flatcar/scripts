# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/sdl-sound/sdl-sound-1.0.3.ebuild,v 1.11 2012/11/25 09:16:25 grobian Exp $

EAPI=2
inherit autotools eutils

MY_P="${P/sdl-/SDL_}"
DESCRIPTION="A library that handles the decoding of sound file formats"
HOMEPAGE="http://icculus.org/SDL_sound/"
SRC_URI="http://icculus.org/SDL_sound/downloads/${MY_P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ~arm ppc ppc64 sparc x86 ~x86-fbsd ~x64-macos"
IUSE="flac mikmod modplug mp3 mpeg physfs speex static-libs vorbis"

RDEPEND=">=media-libs/libsdl-1.2
	flac? ( media-libs/flac )
	mikmod? ( >=media-libs/libmikmod-3.1.9 )
	modplug? ( media-libs/libmodplug )
	vorbis? ( >=media-libs/libvorbis-1.0_beta4 )
	speex? ( media-libs/speex media-libs/libogg )
	physfs? ( dev-games/physfs )
	mpeg? ( media-libs/smpeg )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

S=${WORKDIR}/${MY_P}

src_prepare() {
	epatch "${FILESDIR}"/${P}-underlinking.patch
	eautoreconf
}

src_configure() {
	econf \
		--disable-dependency-tracking \
		--enable-midi \
		$(use_enable mpeg smpeg) \
		$(use_enable mp3 mpglib) \
		$(use_enable flac) \
		$(use_enable speex) \
		$(use_enable static-libs static) \
		$(use_enable mikmod) \
		$(use_enable modplug) \
		$(use_enable physfs) \
		$(use_enable vorbis ogg)
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc CHANGELOG CREDITS README TODO
	if ! use static-libs ; then
		find "${D}" -type f -name '*.la' -exec rm {} + \
			|| die "la removal failed"
	fi
}
