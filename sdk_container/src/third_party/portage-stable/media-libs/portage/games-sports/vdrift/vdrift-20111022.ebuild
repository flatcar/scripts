# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-sports/vdrift/vdrift-20111022.ebuild,v 1.5 2012/07/24 16:52:50 mr_bones_ Exp $

EAPI=2
inherit eutils scons-utils games

MY_P=${PN}-${PV:0:4}-${PV:4:2}-${PV:6:2}
DESCRIPTION="A driving simulation made with drift racing in mind"
HOMEPAGE="http://vdrift.net/"
SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.bz2"

LICENSE="GPL-3 ZLIB"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND="app-arch/libarchive
	media-libs/glew
	media-libs/libsdl[opengl,video]
	media-libs/sdl-gfx
	media-libs/sdl-image[png]
	media-libs/libvorbis
	net-misc/curl
	sci-physics/bullet[-double-precision]
	virtual/opengl
	virtual/glu"
DEPEND="${RDEPEND}
	dev-cpp/asio
	dev-libs/boost
	virtual/pkgconfig"

S=${WORKDIR}/${MY_P}

src_prepare() {
	epatch "${FILESDIR}"/${P}-build.patch
}

src_compile() {
	escons \
		force_feedback=1 \
		destdir="${D}" \
		bindir="${GAMES_BINDIR}" \
		datadir="${GAMES_DATADIR}"/${PN} \
		prefix= \
		use_binreloc=0 \
		release=1 \
		os_cc=1 \
		os_cxx=1 \
		os_cxxflags=1 \
		|| die
}

src_install() {
	dogamesbin build/vdrift || die
	insinto "${GAMES_DATADIR}/${PN}"
	doins -r data/* || die
	newicon data/textures/icons/vdrift-64x64.png ${PN}.png
	make_desktop_entry ${PN} VDrift
	find "${D}" -name "SCon*" -exec rm \{\} +
	cd "${D}"
	keepdir $(find "${GAMES_DATADIR/\//}/${PN}" -type d -empty)
	prepgamesdirs
}
