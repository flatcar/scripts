# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-rpg/pcgen/pcgen-6.00.0.ebuild,v 1.3 2013/01/22 17:29:01 ago Exp $

EAPI=5
inherit versionator gnome2-utils games

MY_PV=$(delete_all_version_separators)
DESCRIPTION="D&D character generator"
HOMEPAGE="http://pcgen.sourceforge.net/"
SRC_URI="mirror://sourceforge/pcgen/pcgen${MY_PV}_full.zip"

LICENSE="LGPL-2.1 OGL-1.0a"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND=">=virtual/jre-1.6"
DEPEND="app-arch/unzip"

S=${WORKDIR}/pcgen${MY_PV}

src_prepare() {
	rm -f *.bat
	sed -i "/dirname/ c\cd \"${GAMES_DATADIR}\/${PN}\"" pcgen.sh || die
	mv -f pcgen.sh "${T}"/${PN}
}

src_install() {
	dogamesbin "${T}"/${PN}
	insinto "${GAMES_DATADIR}"/${PN}
	doins -r *
	keepdir "${GAMES_DATADIR}"/${PN}/characters
	newicon -s 128 system/sponsors/pcgen/pcgen_128x128.png ${PN}.png
	make_desktop_entry ${PN} PCGen
	prepgamesdirs
}

pkg_preinst() {
	games_pkg_preinst
	gnome2_icon_savelist
}

pkg_postinst() {
	games_pkg_postinst
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
