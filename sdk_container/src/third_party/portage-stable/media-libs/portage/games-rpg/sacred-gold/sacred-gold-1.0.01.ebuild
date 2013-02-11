# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-rpg/sacred-gold/sacred-gold-1.0.01.ebuild,v 1.3 2012/03/01 06:55:05 ulm Exp $

inherit versionator eutils cdrom unpacker games

PV_MAJOR=$(get_version_component_range 1-2)
MY_P=sacred-${PV_MAJOR}-${PV}

DESCRIPTION="Action role-playing game"
HOMEPAGE="http://linuxgamepublishing.com/info.php?id=sacred"
SRC_URI="http://updatefiles.linuxgamepublishing.com/sacred/${MY_P}-x86.run"

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
	cp -f "${CDROM_ROOT}"/.data/bin/Linux/x86/sacred* . || die
	cp -f "${CDROM_ROOT}"/README* . || die
	cp -f "${CDROM_ROOT}"/manual.pdf . || die

	mkdir -p patch
	cd patch
	unpack_makeself ${MY_P}-x86.run
	bin/Linux/x86/loki_patch patch.dat "${S}" || die "loki_patch failed"
	cd "${S}"
	rm -rf patch

	mv lib/lib{1,2}/* lib
	rmdir lib/lib{1,2}
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
