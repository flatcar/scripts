# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-rpg/dragonhunt/dragonhunt-3.56.ebuild,v 1.5 2010/05/05 05:07:50 tupone Exp $

EAPI=2
PYTHON_DEPEND="2"
inherit eutils python games

MY_P="Dragon_Hunt-${PV}"
DESCRIPTION="A simple graphical RPG"
HOMEPAGE="http://emhsoft.com/dh.html"
SRC_URI="http://emhsoft.com/dh/${MY_P}.tar.gz"

LICENSE="GPL-2 CCPL-ShareAlike-1.0"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND="dev-python/pygame"

S=${WORKDIR}/${MY_P}

pkg_setup() {
	python_set_active_version 2
	games_pkg_setup
}

src_prepare() {
	# Where to look for modules to load.
	sed -i "s:\.\./modules/:${GAMES_DATADIR}/${PN}/:" \
		code/g.py \
		code/map_editor.py \
		code/rpg.py \
		|| die "Could not change module path."

	# Where to look for keybinding
	sed -i "s:\.\./settings:${GAMES_SYSCONFDIR}/${PN}/settings:" \
		code/g.py \
		|| die "Could not change settings.txt directory"

	# Save games in ~/.${PN}/.
	sed -i \
		-e "s:^\(from os import.*\):\1\, environ:" \
		-e "s:g.mod_dir.*\"/saves/\?\":environ[\"HOME\"] + \"/.${PN}/\":" \
		code/g.py code/loadgame.py \
		|| die "Could not change savegames location."

	# Save maps in ~/.
	sed -i \
		-e "s:^\(from os import.*\):\1\, environ:" \
		-e "s:g.mod_dir.*\"map\.txt\":environ[\"HOME\"]\ +\ \"/dh_map.txt\":" \
		code/map_editor.py \
		|| die "Could not change map location."
}

src_install() {
	insinto "${GAMES_DATADIR}"/${PN}
	doins -r modules/* || die "doins modules failed"

	insinto "${GAMES_SYSCONFDIR}"/${PN}
	doins settings.txt || die "doins settings.txt failed"

	insinto "$(games_get_libdir)"/${PN}
	doins code/*.py || die "doins code failed"

	games_make_wrapper ${PN} "$(PYTHON) ./rpg.py" "$(games_get_libdir)"/${PN}
	games_make_wrapper ${PN}-mapeditor "$(PYTHON) ./map_editor.py" \
		"$(games_get_libdir)"/${PN}

	newicon modules/default/images/buttons/icon.png ${PN}.png
	make_desktop_entry ${PN} "Dragon Hunt"
	make_desktop_entry ${PN}-mapeditor "Dragon Hunt - Editor"

	dodoc README.txt docs/{Changelog,Items.txt,example_map.txt,tiles.txt}
	dohtml docs/*.html
	prepgamesdirs
}

pkg_postinst() {
	games_pkg_postinst
	echo
	elog "If you use the map editor then note that maps will be saved as"
	elog "~/dh_map.txt and must be move to the correct module directory"
	elog "(within ${GAMES_DATADIR}/${PN}) by hand."
	echo
}
