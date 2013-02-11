# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/agg/agg-2.5.ebuild,v 1.16 2012/05/05 03:52:29 jdhore Exp $

inherit eutils autotools

DESCRIPTION="Anti-Grain Geometry - A High Quality Rendering Engine for C++"
HOMEPAGE="http://antigrain.com/"
SRC_URI="http://antigrain.com/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~hppa ppc sparc x86 ~x86-fbsd"
IUSE="sdl truetype X"

RDEPEND="sdl? ( >=media-libs/libsdl-1.2.0 )
	X? ( x11-libs/libX11 )
	truetype? ( >=media-libs/freetype-2 )"
	# sdl.m4 missing in the tarball
DEPEND="media-libs/libsdl
	virtual/pkgconfig
	${RDEPEND}"

src_unpack() {
	unpack ${A}
	cd "${S}"
	sed -r -i \
		-e 's:^(.*)  -L@.*:\1:' \
		src/platform/X11/Makefile.am || die "404"
	eautoreconf
}

src_compile() {
	# examples are not (yet) installed, so do not compile them
	econf \
		--enable-ctrl \
		--enable-gpc \
		--disable-examples \
		$(use_enable sdl sdltest) \
		$(use_enable truetype freetype) \
		$(use_with X x) \
		|| die "econf failed"
	emake || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc readme authors ChangeLog news
}
