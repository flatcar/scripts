# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-rpg/eschalon-book-1-demo/eschalon-book-1-demo-106.ebuild,v 1.4 2013/01/26 21:23:52 tupone Exp $

EAPI=2
inherit eutils games

DESCRIPTION="A classic role-playing game"
HOMEPAGE="http://basiliskgames.com/eschalon-book-i"
SRC_URI="http://dev.gentoo.org/~calchan/distfiles/${P}.tar.gz"

LICENSE="eschalon-book-1-demo"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""
RESTRICT="strip"
QA_PREBUILT="${GAMES_PREFIX_OPT:1}/${PN}/Eschalon Book I Demo"

RDEPEND="x86? ( media-libs/freetype
		virtual/opengl
		virtual/glu
		x11-libs/libX11
		x11-libs/libXxf86vm )
	amd64? ( app-emulation/emul-linux-x86-opengl
		app-emulation/emul-linux-x86-xlibs )"

S="${WORKDIR}/Eschalon Book I Demo"

src_install () {
	insinto "${GAMES_PREFIX_OPT}/${PN}"
	doins -r data music sound *pdf *pak help.txt \
		|| die "doins failed"

	exeinto "${GAMES_PREFIX_OPT}/${PN}"
	doexe "Eschalon Book I Demo" || die "doexe failed"

	make_desktop_entry ${PN} "Eschalon: Book I (Demo)"
	games_make_wrapper ${PN} "\"./Eschalon Book I Demo\"" "${GAMES_PREFIX_OPT}/${PN}"
	prepgamesdirs
}
