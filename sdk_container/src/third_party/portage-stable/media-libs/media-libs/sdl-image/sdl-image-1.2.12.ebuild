# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/sdl-image/sdl-image-1.2.12.ebuild,v 1.10 2012/06/08 19:56:50 mr_bones_ Exp $

EAPI=2
inherit eutils

MY_P="${P/sdl-/SDL_}"
DESCRIPTION="image file loading library"
HOMEPAGE="http://www.libsdl.org/projects/SDL_image/"
SRC_URI="http://www.libsdl.org/projects/SDL_image/release/${MY_P}.tar.gz"

LICENSE="ZLIB"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 ~sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE="gif jpeg png static-libs tiff webp"

DEPEND="sys-libs/zlib
	media-libs/libsdl
	png? ( >=media-libs/libpng-1.4 )
	jpeg? ( virtual/jpeg )
	tiff? ( media-libs/tiff )
	webp? ( media-libs/libwebp )"

S=${WORKDIR}/${MY_P}

src_configure() {
	econf \
		--disable-jpg-shared \
		--disable-png-shared \
		--disable-tif-shared \
		--disable-webp-shared \
		$(use_enable static-libs static) \
		$(use_enable gif) \
		$(use_enable jpeg jpg) \
		$(use_enable tiff tif) \
		$(use_enable png) \
		$(use_enable webp) \
		--enable-bmp \
		--enable-lbm \
		--enable-pcx \
		--enable-pnm \
		--enable-tga \
		--enable-xcf \
		--enable-xpm \
		--enable-xv
}

src_install() {
	emake DESTDIR="${D}" install || die
	dobin .libs/showimage || die
	dodoc CHANGES README
	use static-libs || prune_libtool_files --all
}
