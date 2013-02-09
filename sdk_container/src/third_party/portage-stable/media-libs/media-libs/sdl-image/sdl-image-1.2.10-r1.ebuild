# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/sdl-image/sdl-image-1.2.10-r1.ebuild,v 1.12 2011/03/25 11:24:15 tupone Exp $
EAPI=2

inherit base

MY_P="${P/sdl-/SDL_}"
DESCRIPTION="image file loading library"
HOMEPAGE="http://www.libsdl.org/projects/SDL_image/"
SRC_URI="http://www.libsdl.org/projects/SDL_image/release/${MY_P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE="gif jpeg png static-libs tiff"

DEPEND="sys-libs/zlib
	media-libs/libsdl
	png? ( >=media-libs/libpng-1.4 )
	jpeg? ( virtual/jpeg )
	tiff? ( media-libs/tiff )"
RDEPEND="${DEPEND}"

S=${WORKDIR}/${MY_P}

PATCHES=( "${FILESDIR}"/${P}-libpng15.patch )

src_configure() {
	econf \
		--disable-jpg-shared \
		--disable-png-shared \
		--disable-tif-shared \
		$(use_enable static-libs static) \
		$(use_enable gif) \
		$(use_enable jpeg jpg) \
		$(use_enable tiff tif) \
		$(use_enable png) \
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
	emake DESTDIR="${D}" install || die "make install failed"
	dobin .libs/showimage || die "dobin failed"
	dodoc CHANGES README
	if ! use static-libs ; then
		find "${D}" -type f -name '*.la' -exec rm {} + \
			|| die "la removal failed"
	fi
}
