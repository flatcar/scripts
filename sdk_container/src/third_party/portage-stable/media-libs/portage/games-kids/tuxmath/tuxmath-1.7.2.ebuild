# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-kids/tuxmath/tuxmath-1.7.2.ebuild,v 1.5 2012/08/06 22:29:18 mr_bones_ Exp $

EAPI=2
inherit eutils games

MY_PN="${PN}_w_fonts"
DESCRIPTION="Educational arcade game where you have to solve maths problems"
HOMEPAGE="http://tux4kids.alioth.debian.org/tuxmath/"
SRC_URI="mirror://sourceforge/tuxmath/${MY_PN}-${PV}.tar.gz"

LICENSE="GPL-2 OFL-1.1"
SLOT="0"
KEYWORDS="amd64 ppc x86 ~x86-fbsd"
IUSE="nls"

RDEPEND="media-libs/libsdl
	media-libs/sdl-pango
	media-libs/sdl-image[jpeg,png]
	media-libs/sdl-mixer[mod]
	nls? ( virtual/libintl )"
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )"

S=${WORKDIR}/${MY_PN}-${PV}

src_prepare() {
	sed -i \
		-e '/\bdoc\b/d' \
		Makefile.in \
		|| die "sed failed"
}

src_configure() {
	egamesconf \
		--disable-dependency-tracking \
		--localedir=/usr/share/locale \
		$(use_enable nls)
}

src_install()
{
	emake DESTDIR="${D}" install || die "install failed"
	doicon data/images/icons/${PN}.svg
	make_desktop_entry ${PN} "TuxMath"
	dodoc doc/{README.txt,TODO.txt,changelog}
	prepgamesdirs
}
