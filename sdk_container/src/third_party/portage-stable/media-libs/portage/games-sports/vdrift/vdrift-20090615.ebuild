# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-sports/vdrift/vdrift-20090615.ebuild,v 1.6 2010/10/14 01:59:17 mr_bones_ Exp $

EAPI=2
inherit eutils scons-utils games

MY_P=${PN}-${PV:0:4}-${PV:4:2}-${PV:6}
DESCRIPTION="A driving simulation made with drift racing in mind"
HOMEPAGE="http://vdrift.net/"
SRC_URI="mirror://sourceforge/${PN}/${MY_P}-src.tar.bz2"

LICENSE="GPL-2 ZLIB"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="nls"

RDEPEND="virtual/opengl
	virtual/glu
	media-libs/glew
	media-libs/libsdl[opengl,video]
	media-libs/openal
	media-libs/sdl-gfx
	media-libs/sdl-image[png]
	media-libs/sdl-net
	media-libs/libvorbis
	nls? ( virtual/libintl )"
DEPEND="${RDEPEND}
	dev-cpp/asio
	nls? ( sys-devel/gettext )"

S=${WORKDIR}/${PN}-${PV:0:4}-${PV:4:2}-${PV:6:2}

src_prepare() {
	sed -i \
		-e "s/'-O1',\?//" \
		SConstruct \
		|| die "sed failed"
	epatch "${FILESDIR}"/${P}-ldflags.patch
}

src_compile() {
	escons \
		force_feedback=1 \
		$(use_scons nls NLS) \
		destdir="${D}" \
		bindir="${GAMES_BINDIR}" \
		datadir="${GAMES_DATADIR}"/${PN} \
		localedir=/usr/share/locale \
		prefix= \
		use_binreloc=0 \
		release=1 \
		os_cc=1 \
		os_cxx=1 \
		os_cxxflags=1 \
		|| die
}

src_install() {
	dogamesbin build/vdrift || die "dogamesbin failed"
	insinto "${GAMES_DATADIR}/${PN}"
	doins -r data/* || die "doins failed"
	newicon data/textures/icons/vdrift-64x64.png ${PN}.png
	make_desktop_entry ${PN} VDrift
	dodoc docs/*
	find "${D}" -name "SCon*" -exec rm \{\} +
	cd "${D}"
	keepdir $(find "${GAMES_DATADIR/\//}/${PN}" -type d -empty)
	prepgamesdirs
}
