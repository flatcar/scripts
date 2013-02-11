# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-sports/trigger/trigger-0.6.0.ebuild,v 1.4 2012/11/01 20:54:54 mr_bones_ Exp $

EAPI=2
inherit eutils games

MY_PN=${PN}-rally
MY_P=${MY_PN}-${PV}
DESCRIPTION="Free OpenGL rally car racing game"
HOMEPAGE="http://www.positro.net/trigger/"
SRC_URI="mirror://sourceforge/${MY_PN}/${MY_P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE=""

RDEPEND="virtual/opengl
	virtual/glu
	media-libs/libsdl
	media-libs/sdl-image[jpeg,png]
	media-libs/sdl-mixer
	media-libs/openal
	media-libs/freealut
	dev-games/physfs"
DEPEND="${RDEPEND}
	dev-util/ftjam"

S=${WORKDIR}/${MY_P}

PATCHES=( "${FILESDIR}"/${P}-ldflags.patch )

src_configure() {
	egamesconf --datadir="${GAMES_DATADIR}"/${PN} || die
}

src_compile() {
	AR="${AR} cru" jam -dx -qa || die "jam failed"
}

src_install() {
	dogamesbin ${PN} || die
	insinto "${GAMES_DATADIR}"/${PN}
	doins -r data/* || die
	newicon data/textures/life_helmet.png ${PN}.png
	make_desktop_entry ${PN} Trigger
	dodoc doc/*.txt
	prepgamesdirs
}

pkg_postinst() {
	games_pkg_postinst
	elog "After running ${PN} for the first time, a config file is"
	elog "available in ~/.trigger/trigger.config"
}
