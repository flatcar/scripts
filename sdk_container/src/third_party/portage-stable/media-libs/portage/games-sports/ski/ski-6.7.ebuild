# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-sports/ski/ski-6.7.ebuild,v 1.5 2011/01/30 18:38:50 armin76 Exp $

EAPI=2
PYTHON_DEPEND="2"
inherit python games

DESCRIPTION="A simple text-mode skiing game"
HOMEPAGE="http://www.catb.org/~esr/ski/"
SRC_URI="http://www.catb.org/~esr/ski/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE=""

DEPEND=""
RDEPEND=""

src_prepare() {
	python_convert_shebangs -r 2 .
}

src_install() {
	dogamesbin ski || die "dogamesbin failed"
	doman ski.6 || die "doman failed"
	dodoc README
	prepgamesdirs
}

pkg_setup() {
	python_set_active_version 2
	games_pkg_setup
}
