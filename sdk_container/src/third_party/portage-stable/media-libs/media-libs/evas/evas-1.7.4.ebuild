# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/evas/evas-1.7.4.ebuild,v 1.1 2012/12/21 19:50:46 tommy Exp $

EAPI=2

inherit enlightenment

DESCRIPTION="hardware-accelerated retained canvas API"
HOMEPAGE="http://trac.enlightenment.org/e/wiki/Evas"
SRC_URI="http://download.enlightenment.org/releases/${P}.tar.bz2"

LICENSE="BSD-2"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="altivec bidi +bmp directfb +eet fbcon +fontconfig gles gif +ico +jpeg mmx opengl +png +ppm +psd sse sse3 static-libs tga +threads tiff X xcb xpm"

RDEPEND=">=dev-libs/eina-1.7.0
	>=media-libs/freetype-2.3.9
	fontconfig? ( media-libs/fontconfig )
	gles? ( media-libs/mesa[gallium,gles2] )
	gif? ( media-libs/giflib )
	jpeg? ( virtual/jpeg )
	png? ( media-libs/libpng )
	bidi? ( >=dev-libs/fribidi-0.19.1 )
	directfb? ( >=dev-libs/DirectFB-0.9.16 )
	tiff? ( media-libs/tiff )
	xpm? ( x11-libs/libXpm )
	X? (
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXrender
		opengl? ( virtual/opengl )
	)
	!X? (
		xcb? (
			x11-libs/xcb-util
		) )
	eet? ( >=dev-libs/eet-1.7.0 )"
DEPEND="${RDEPEND}"

src_configure() {
	if use X ; then
		if use xcb ; then
			ewarn "You have enabled both 'X' and 'xcb', so we will use"
			ewarn "X as it's considered the most stable for evas"
		fi
		MY_ECONF="
			--disable-software-xcb
			$(use_enable opengl gl-xlib)
		"
	elif use xcb ; then
		MY_ECONF="
			--disable-gl-xlib
			--enable-software-xcb
			$(use_enable opengl gl-xcb)
		"
	else
		MY_ECONF="
			--disable-gl-xlib
			--disable-software-xcb
			--disable-gl-xcb
		"
	fi

	MY_ECONF+="
		$(use_enable altivec cpu-altivec)
		$(use_enable bidi fribidi)
		$(use_enable bmp image-loader-bmp)
		$(use_enable bmp image-loader-wbmp)
		$(use_enable directfb)
		$(use_enable doc)
		$(use_enable eet font-loader-eet)
		$(use_enable eet image-loader-eet)
		$(use_enable fbcon fb)
		$(use_enable fontconfig)
		$(use_enable gles gl-flavor-gles)
		$(use_enable gles gles-variety-sgx)
		$(use_enable gif image-loader-gif)
		$(use_enable ico image-loader-ico)
		$(use_enable jpeg image-loader-jpeg)
		$(use_enable mmx cpu-mmx)
		$(use_enable png image-loader-png)
		$(use_enable ppm image-loader-pmaps)
		$(use_enable psd image-loader-psd)
		$(use_enable sse cpu-sse)
		$(use_enable sse3 cpu-sse3)
		--disable-image-loader-svg
		$(use_enable tga image-loader-tga)
		$(use_enable tiff image-loader-tiff)
		$(use_enable threads pthreads)
		$(use_enable threads async-events)
		$(use_enable threads async-preload)
		$(use_enable X software-xlib)
		$(use_enable xpm image-loader-xpm)
		--enable-evas-magic-debug \
		--enable-static-software-generic \
		--enable-buffer \
		--enable-cpu-c \
		--enable-scale-sample \
		--enable-scale-smooth \
		--enable-convert-8-rgb-332 \
		--enable-convert-8-rgb-666 \
		--enable-convert-8-rgb-232 \
		--enable-convert-8-rgb-222 \
		--enable-convert-8-rgb-221 \
		--enable-convert-8-rgb-121 \
		--enable-convert-8-rgb-111 \
		--enable-convert-16-rgb-565 \
		--enable-convert-16-rgb-555 \
		--enable-convert-16-rgb-444 \
		--enable-convert-16-rgb-rot-0 \
		--enable-convert-16-rgb-rot-270 \
		--enable-convert-16-rgb-rot-90 \
		--enable-convert-24-rgb-888 \
		--enable-convert-24-bgr-888 \
		--enable-convert-32-rgb-8888 \
		--enable-convert-32-rgbx-8888 \
		--enable-convert-32-bgr-8888 \
		--enable-convert-32-bgrx-8888 \
		--enable-convert-32-rgb-rot-0 \
		--enable-convert-32-rgb-rot-270 \
		--enable-convert-32-rgb-rot-90 \
		--enable-image-loader-generic \
		--disable-harfbuzz \
		--disable-image-loader-edb \
		--disable-static-software-16 \
		--disable-software-16-x11"

	enlightenment_src_configure
}

pkg_postinst() {
	elog "for svg support install media-plugins/evas_generic_loaders[svg]"
}
