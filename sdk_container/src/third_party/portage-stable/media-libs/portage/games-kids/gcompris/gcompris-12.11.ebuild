# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-kids/gcompris/gcompris-12.11.ebuild,v 1.4 2013/01/22 17:21:54 ago Exp $

EAPI=5
PYTHON_DEPEND="2:2.6"
PYTHON_USE_WITH="sqlite threads"

inherit autotools eutils python games

DESCRIPTION="full featured educational application for children from 2 to 10"
HOMEPAGE="http://gcompris.net/"
SRC_URI="mirror://sourceforge/gcompris/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE="gstreamer"

RDEPEND="x11-libs/gtk+:2
	gnome-base/librsvg[gtk]
	gstreamer? (
		media-libs/gstreamer:0.10
		media-libs/gst-plugins-good:0.10
		media-plugins/gst-plugins-ogg:0.10
		media-plugins/gst-plugins-alsa:0.10
		media-plugins/gst-plugins-vorbis:0.10 )
	!gstreamer? (
		media-libs/sdl-mixer
		media-libs/libsdl )
	dev-libs/libxml2
	dev-libs/popt
	virtual/libintl
	games-board/gnuchess
	dev-db/sqlite:3
	dev-python/pygtk"
DEPEND="${RDEPEND}
	gnome-base/gnome-common
	dev-perl/XML-Parser
	sys-devel/gettext
	sys-apps/texinfo
	app-text/texi2html
	virtual/pkgconfig"
RDEPEND="${RDEPEND}
	media-gfx/tuxpaint
	sci-electronics/gnucap"

pkg_setup() {
	python_set_active_version 2
	python_pkg_setup
	games_pkg_setup
}

src_prepare() {
	# Drop DEPRECATED flags, bug #387817
	sed -i -e 's:-D[A-Z_]*DISABLE_DEPRECATED:$(NULL):g' \
		src/gcompris/Makefile.am src/gcompris/Makefile.in \
		src/goocanvas/src/Makefile.am src/goocanvas/src/Makefile.in \
		|| die

	epatch "${FILESDIR}"/${P}-build.patch
	cp /usr/share/gettext/config.rpath .
	eautoreconf
	sed -i \
		-e 's#^itlocaledir =.*$#itlocaledir = @localedir@#' \
		po/Makefile.in.in || die

	# Fix desktop files
	sed -i \
		-e '/Encoding/d' \
		gcompris.desktop.in \
		gcompris-edit.desktop.in || die
}

src_configure() {
	GNUCHESS="${GAMES_BINDIR}"/gnuchess \
	egamesconf \
		--datarootdir="${GAMES_DATADIR}" \
		--datadir="${GAMES_DATADIR}" \
		--localedir=/usr/share/locale \
		--infodir=/usr/share/info \
		--with-python="$(PYTHON -a)" \
		$(use_enable !gstreamer sdlmixer) \
		--enable-sqlite \
		--enable-py-build-only
}

src_compile() {
	emake -j1
}

src_install() {
	emake DESTDIR="${D}" install
	prune_libtool_files --modules
	dodoc AUTHORS ChangeLog NEWS README THANKS TODO
	prepgamesdirs
}
