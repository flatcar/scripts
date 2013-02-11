# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-kids/tuxmathscrabble/tuxmathscrabble-7.4.ebuild,v 1.4 2011/03/04 12:58:07 ranger Exp $

EAPI=2
PYTHON_DEPEND="2"
inherit eutils python multilib games

MY_PN=TuxMathScrabble
MY_P=${PN}-0.${PV}
DESCRIPTION="math-version of the popular board game for children 4-10"
HOMEPAGE="http://www.asymptopia.org/"
SRC_URI="mirror://gentoo/${MY_P}.zip"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ppc x86"
IUSE=""

CDEPEND="dev-python/wxpython"
DEPEND="${CDEPEND}
	app-arch/unzip"
RDEPEND="${CDEPEND}
	dev-python/pygame"

S=${WORKDIR}/${MY_P}

pkg_setup() {
	python_set_active_version 2
	games_pkg_setup
}

src_prepare() {
	rm -f $(find . -name '*.pyc')
	epatch "${FILESDIR}"/${P}-gentoo.patch
	sed -i \
		-e "s:@GENTOO_DATADIR@:${GAMES_DATADIR}/${MY_PN}:" \
		${MY_PN}/tms.py \
		.tms_config_master \
		|| die "sed failed"
	python_convert_shebangs -r 2 .
}

src_install() {
	newgamesbin ${PN}.py ${PN} || die "newgamesbin failed"

	insinto $(python_get_sitedir)
	doins -r ${MY_PN} || die "doins failed"

	insinto "${GAMES_DATADIR}"/${MY_PN}
	doins -r .tms_config_master Font || die "doins failed"

	newicon tms.ico ${PN}.ico
	make_desktop_entry ${PN} ${PN} /usr/share/pixmaps/${PN}.ico

	dodoc CHANGES README
	prepgamesdirs
}
