# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-rpg/sacred-gold/sacred-gold-1.0.ebuild,v 1.2 2012/03/01 06:55:05 ulm Exp $

inherit eutils cdrom games

DESCRIPTION="Action role-playing game"
HOMEPAGE="http://linuxgamepublishing.com/info.php?id=sacred"
SRC_URI=""

LICENSE="as-is GPL-2 LGPL-2"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
IUSE=""
RESTRICT="strip"

RDEPEND="virtual/opengl
	x86? ( x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXi )
	amd64? ( app-emulation/emul-linux-x86-xlibs )"
DEPEND=""

S=${WORKDIR}

src_unpack() {
	cdrom_get_cds .data/bin/Linux/x86/sacred
	ln -sfn "${CDROM_ROOT}"/.data cd
	unpack ./cd/data/data.tar.gz
	rm -f cd
	mv lib/lib{1,2}/* lib
	rmdir lib/lib{1,2}
	cp -f "${CDROM_ROOT}"/.data/bin/Linux/x86/sacred* . || die
	cp -f "${CDROM_ROOT}"/README* . || die
	cp -f "${CDROM_ROOT}"/manual.pdf . || die
}

src_install() {
	dir=${GAMES_PREFIX_OPT}/${PN}

	insinto "${dir}"
	mv * "${D}/${dir}" || die

	games_make_wrapper ${PN} ./sacred "${dir}" "${dir}"/lib
	newicon "${CDROM_ROOT}"/.data/icon.xpm ${PN}.xpm || die
	make_desktop_entry ${PN} "Sacred - Gold" ${PN}

	prepgamesdirs
}
