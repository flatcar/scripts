# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gegl/gegl-0.1.6.ebuild,v 1.20 2012/04/14 00:46:10 sping Exp $

EAPI=4

inherit eutils autotools

DESCRIPTION="A graph based image processing framework"
HOMEPAGE="http://www.gegl.org/"
SRC_URI="ftp://ftp.gimp.org/pub/${PN}/${PV:0:3}/${P}.tar.bz2"

LICENSE="|| ( GPL-3 LGPL-3 )"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x64-solaris ~x86-solaris"

IUSE="cairo debug exif ffmpeg graphviz jpeg jpeg2k lua mmx openexr png raw sdl sse svg umfpack v4l"

DEPEND=">=media-libs/babl-0.1.4 <media-libs/babl-0.1.8
	dev-libs/glib:2
	x11-libs/gtk+:2
	x11-libs/gdk-pixbuf:2
	x11-libs/pango
	sys-libs/zlib
	cairo? ( x11-libs/cairo )
	exif? ( media-gfx/exiv2 )
	ffmpeg? ( virtual/ffmpeg )
	graphviz? ( media-gfx/graphviz )
	jpeg? ( virtual/jpeg )
	jpeg2k? ( media-libs/jasper )
	lua? ( dev-lang/lua )
	openexr? ( media-libs/openexr )
	png? ( media-libs/libpng )
	raw? ( media-libs/libopenraw )
	sdl? ( media-libs/libsdl )
	svg? ( gnome-base/librsvg:2 )
	umfpack? ( sci-libs/umfpack )
	v4l? ( media-libs/libv4l )"
RDEPEND="${DEPEND}"

# tests fail in various ways:
#   see bug #362215
RESTRICT="test"

DOCS=( ChangeLog INSTALL README NEWS )

src_prepare() {
	# upstream bug report:
	# https://bugzilla.gnome.org/show_bug.cgi?id=642494
	epatch "${FILESDIR}"/gegl-doubledestdir.diff

	# new ffmpeg api
	epatch "${FILESDIR}/${PV}-ffmpeg.patch"

	# fix OSX loadable module filename extension
	sed -i -e 's/\.dylib/.bundle/' configure.ac || die
	eautoreconf
}

src_configure() {
	# never enable altering of CFLAGS via profile option
	# libspiro: not in portage main tree
	# disable documentation as the generating is bit automagic
	#    if anyone wants to work on it just create bug with patch
	# gtk and friends: always enable
	econf \
		--disable-profile \
		--without-libspiro \
		--disable-docs --disable-workshop \
		--with-gtk --with-pango --with-gdk-pixbuf --with-gio \
		$(use_enable mmx) \
		$(use_enable sse) \
		$(use_enable debug) \
		$(use_with cairo) \
		$(use_with cairo pangocairo) \
		$(use_with exif exiv2) \
		$(use_with ffmpeg libavformat) \
		$(use_with graphviz) \
		$(use_with jpeg libjpeg) \
		$(use_with jpeg2k jasper) \
		$(use_with lua) \
		$(use_with openexr) \
		$(use_with png libpng) \
		$(use_with raw libopenraw) \
		$(use_with sdl) \
		$(use_with svg librsvg) \
		$(use_with umfpack) \
		$(use_with v4l libv4l)
}

src_test() {
	# set xdg dirs to not violate sandbox constrains
	export XDG_CONFIG_HOME="${T}"
	export XDG_CACHE_HOME="${T}"

	default
}

src_install() {
	default
	find "${ED}" -name '*.la' -delete
}
