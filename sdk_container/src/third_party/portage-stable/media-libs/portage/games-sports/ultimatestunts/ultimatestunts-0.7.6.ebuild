# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-sports/ultimatestunts/ultimatestunts-0.7.6.ebuild,v 1.3 2012/07/15 07:37:42 hasufell Exp $

EAPI=2
inherit autotools eutils versionator games

MY_P=${PN}-srcdata-$(replace_all_version_separators)1
DESCRIPTION="Remake of the famous Stunts game"
HOMEPAGE="http://www.ultimatestunts.nl/"
SRC_URI="mirror://sourceforge/ultimatestunts/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 x86"
IUSE="nls"

RDEPEND="media-libs/libsdl[joystick,opengl,video]
	media-libs/sdl-image
	>=media-libs/openal-1
	media-libs/libvorbis
	media-libs/freealut
	virtual/opengl
	virtual/glu
	nls? ( virtual/libintl )"
DEPEND="${RDEPEND}
	sys-devel/gettext"

S=${WORKDIR}/${MY_P}

src_prepare() {
	ecvs_clean
	epatch "${FILESDIR}"/${P}-paths.patch \
		"${FILESDIR}"/${P}-gcc-4.7.patch
	autopoint -f || die "autopoint failed"
	AT_M4DIR=m4 eautoreconf
}

src_configure() {
	egamesconf \
		--disable-dependency-tracking \
		--with-openal \
		$(use_enable nls)
	sed -i \
		-e "/^datadir/s:= .*:= ${GAMES_DATADIR}/${PN}:" \
		${PN}.conf \
		|| die
}

src_compile() {
	emake -C trackedit libtrackedit.a || die
	emake || die
}

src_install() {
	emake DESTDIR="${D}" install || die
	newicon data/cars/diablo/steer.png ${PN}.png || die
	make_desktop_entry ustunts "Ultimate Stunts" || die
	dodoc AUTHORS README
	prepgamesdirs
}
