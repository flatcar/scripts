# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-rpg/twclone/twclone-0.14.ebuild,v 1.5 2006/11/24 16:00:15 nyhm Exp $

inherit games

MY_P="${PN}-source-${PV}"
DESCRIPTION="Clone of BBS Door game Trade Wars 2002"
HOMEPAGE="http://twclone.sourceforge.net/"
SRC_URI="mirror://sourceforge/twclone/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc x86"
IUSE=""

S=${WORKDIR}/${MY_P}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc AUTHORS ChangeLog PROTOCOL README TODO
	cd "${D}/${GAMES_BINDIR}"
	for f in * ; do
		mv {,${PN}-}${f}
	done
	prepgamesdirs
}
