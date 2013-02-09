# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/devil/devil-1.7.8-r1.ebuild,v 1.7 2012/12/17 20:35:24 ago Exp $

EAPI=2

inherit autotools eutils

MY_P=DevIL-${PV}

DESCRIPTION="DevIL image library"
HOMEPAGE="http://openil.sourceforge.net/"
SRC_URI="mirror://sourceforge/openil/${MY_P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ppc ~ppc64 x86"
IUSE="allegro gif glut jpeg lcms mng nvtt openexr opengl png sdl sse sse2 sse3 static-libs tiff xpm X"

RDEPEND="allegro? ( media-libs/allegro:0 )
	gif? ( media-libs/giflib )
	glut? ( media-libs/freeglut )
	jpeg? ( virtual/jpeg )
	lcms? ( =media-libs/lcms-1* )
	mng? ( media-libs/libmng )
	nvtt? ( media-gfx/nvidia-texture-tools )
	openexr? ( media-libs/openexr )
	opengl? ( virtual/opengl
		virtual/glu )
	png? ( media-libs/libpng:0 )
	sdl? ( media-libs/libsdl )
	tiff? ( media-libs/tiff:0 )
	xpm? ( x11-libs/libXpm )
	X? ( x11-libs/libXext
		 x11-libs/libX11
		 x11-libs/libXrender )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	X? ( x11-proto/xextproto )"

src_prepare() {
	epatch "${FILESDIR}"/${P}-{CVE-2009-3994,libpng14,nvtt-glut,ILUT}.patch
	eautoreconf
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		--disable-dependency-tracking \
		--enable-ILU \
		--enable-ILUT \
		$(use_enable sse) \
		$(use_enable sse2) \
		$(use_enable sse3) \
		$(use_enable openexr exr) \
		$(use_enable gif) \
		$(use_enable jpeg) \
		$(use_enable lcms) \
		$(use_enable mng) \
		$(use_enable png) \
		$(use_enable tiff) \
		$(use_enable xpm) \
		$(use_enable allegro) \
		--disable-directx8 \
		--disable-directx9 \
		$(use_enable opengl) \
		$(use_enable sdl) \
		$(use_enable X x11) \
		$(use_enable X shm) \
		$(use_enable X render) \
		$(use_enable glut) \
		$(use_with X x) \
		$(use_with nvtt)
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS CREDITS ChangeLog NEWS README* TODO || die
	if ! use static-libs ; then
		find "${D}" -type f -name '*.la' -exec rm {} + \
			|| die "la removal failed"
	fi
}
