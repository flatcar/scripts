# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-rpg/freedroidrpg/freedroidrpg-0.15.ebuild,v 1.5 2013/02/01 00:03:14 mr_bones_ Exp $

EAPI=2
PYTHON_DEPEND="2"
inherit eutils python games

DESCRIPTION="A modification of the classical Freedroid engine into an RPG"
HOMEPAGE="http://freedroid.sourceforge.net/"
SRC_URI="mirror://sourceforge/freedroid/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE="opengl vorbis"

RDEPEND="media-libs/libsdl[opengl?,video]
	dev-lang/lua
	virtual/jpeg
	media-libs/libpng
	media-libs/sdl-image[jpeg,png]
	media-libs/sdl-mixer[vorbis?]
	>=media-libs/sdl-gfx-2.0.21
	vorbis? ( media-libs/libogg media-libs/libvorbis )
	x11-libs/libX11
	opengl? ( virtual/opengl )"
DEPEND="${RDEPEND}
	dev-lang/python"

pkg_setup() {
	python_set_active_version 2
	games_pkg_setup
}

src_prepare() {
	python_convert_shebangs -r 2 .

	# No need for executable game resources
	find sound graphics -type f -exec chmod -c a-x '{}' +
}

src_configure() {
	egamesconf \
		--disable-dependency-tracking \
		--disable-fastmath \
		$(use_enable opengl) \
		$(use_enable vorbis)
}

src_install() {
	emake DESTDIR="${D}" install || die
	rm -f "${D}/${GAMES_BINDIR}/"{croppy,pngtoico,*glue*,explode*,make_atlas}
	newicon win32/w32icon2_64x64.png ${PN}.png
	make_desktop_entry freedroidRPG "Freedroid RPG"
	prepgamesdirs
}
