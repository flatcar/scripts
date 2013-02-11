# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-rpg/sumwars/sumwars-0.5.6-r2.ebuild,v 1.6 2012/07/03 09:03:12 jdhore Exp $

EAPI=4

inherit cmake-utils eutils flag-o-matic gnome2-utils games

DESCRIPTION="a multi-player, 3D action role-playing game"
HOMEPAGE="http://sumwars.org"
SRC_URI="mirror://sourceforge/sumwars/${P//_/-}-src.tar.bz2"

LICENSE="GPL-3 CCPL-Attribution-ShareAlike-3.0"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="+tools debug"

LANGS="de en it pl pt ru uk"
for L in ${LANGS} ; do
	IUSE="${IUSE} linguas_${L}"
done
unset L

DEPEND="
	>=dev-games/cegui-0.7.6-r1[ogre]
	!>=dev-games/cegui-0.8
	>=dev-games/ogre-1.7.4-r1[freeimage,opengl]
	!>=dev-games/ogre-1.9
	dev-games/ois
	dev-games/physfs
	=dev-lang/lua-5.1*
	>=dev-libs/tinyxml-2.6.2-r2
	media-libs/freealut
	media-libs/openal
	media-libs/libogg
	media-libs/libvorbis
	>=net-libs/enet-1.3.0
	x11-libs/libXrandr
	tools? ( dev-libs/poco )"

S=${WORKDIR}/${PN}-${PV%_*}

src_prepare() {
	epatch "${FILESDIR}"/${P}-build.patch
}

src_configure() {
	# QA
	append-flags -fno-strict-aliasing

	use debug && CMAKE_BUILD_TYPE=Debug

	local l langs
	for l in ${LANGS}; do
		if use linguas_${l}; then
			langs="${langs} ${l}"
		fi
	done

	[ -z "${langs}" ] && langs="en"

	# configure sumwars with cmake
	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX=""
		-DSUMWARS_LANGUAGES="${langs}"
		-DSUMWARS_NO_TINYXML=ON
		-DSUMWARS_NO_ENET=ON
		-DSUMWARS_DOC_DIR="/usr/share/doc/${PF}"
		-DSUMWARS_EXECUTABLE_DIR="${GAMES_BINDIR}"
		-DSUMWARS_SHARE_DIR="${GAMES_DATADIR}/${PN}"
		-DSUMWARS_STANDALONE_MODE=OFF
		-DSUMWARS_POST_BUILD_COPY=OFF
		-DSUMWARS_PORTABLE_MODE=OFF
		-DSUMWARS_RANDOM_REGIONS=ON
		$(cmake-utils_use tools SUMWARS_BUILD_TOOLS)
	)

	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
}

src_install() {
	cmake-utils_src_install
	newicon -s 128 share/icon/SumWarsIcon_128x128.png ${PN}.png
	make_desktop_entry ${PN} "Summoning Wars"
	prepgamesdirs
}

pkg_preinst() {
	games_pkg_preinst
	gnome2_icon_savelist
}

pkg_postinst() {
	games_pkg_postinst
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
