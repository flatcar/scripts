# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/wxsvg/wxsvg-1.1.9.ebuild,v 1.3 2012/12/16 13:50:43 ago Exp $

EAPI=4
WX_GTK_VER=2.8
inherit eutils wxwidgets

DESCRIPTION="C++ library to create, manipulate and render SVG files"
HOMEPAGE="http://wxsvg.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="wxWinLL-3"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="static-libs"

RDEPEND=">=dev-libs/expat-2.0.1-r3
	>=dev-libs/glib-2.12
	>=dev-libs/libxml2-2.6.26
	>=media-libs/fontconfig-2.4
	>=media-libs/freetype-2.2.0
	x11-libs/cairo
	>=x11-libs/pango-1.14.9
	x11-libs/wxGTK:2.8[X]
	virtual/ffmpeg"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

DOCS=( AUTHORS ChangeLog TODO )

src_configure() {
	econf \
		$(use_enable static-libs static) \
		--with-wx-config=${WX_CONFIG}
}

src_install() {
	default
	prune_libtool_files
}
