# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-kids/memonix-bin/memonix-bin-1.6.ebuild,v 1.4 2009/11/21 19:33:55 maekke Exp $

inherit eutils games

MY_PN=${PN%-bin}
DESCRIPTION="Brain teasers, puzzle and memory games for kid's in one pack"
HOMEPAGE="http://www.viewizard.com/memonix/"
SRC_URI="http://www.viewizard.com/download/memx${PV//./}.tar.gz
	mirror://gentoo/memonix-addons-1.tar.bz2"

LICENSE="Memonix"
SLOT="0"
KEYWORDS="x86"
IUSE=""
RESTRICT="strip"

DEPEND=""
RDEPEND=""

S=${WORKDIR}/Memonix

src_install() {
	exeinto "${GAMES_PREFIX_OPT}/${MY_PN}"
	doexe Memonix || die "doexe failed"
	insinto "${GAMES_PREFIX_OPT}/${MY_PN}"
	doins gamedata.vfs "${WORKDIR}"/addons/* || die "doins failed"
	dodoc Changes ReadMe

	games_make_wrapper ${MY_PN} "./Memonix" "${GAMES_PREFIX_OPT}/${MY_PN}"
	newicon icon48.png ${MY_PN}.png || die "newicon failed"
	make_desktop_entry ${MY_PN} "Memonix" ${MY_PN}
	prepgamesdirs
}
