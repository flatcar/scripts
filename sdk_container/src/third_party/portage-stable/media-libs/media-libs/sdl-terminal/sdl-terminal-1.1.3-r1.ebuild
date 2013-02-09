# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/sdl-terminal/sdl-terminal-1.1.3-r1.ebuild,v 1.5 2012/12/04 15:39:59 ago Exp $

EAPI=4
inherit base libtool

MY_P="${P/sdl-/SDL_}"
DESCRIPTION="library that provides a pseudo-ansi color terminal that can be used with any SDL application"
HOMEPAGE="http://www.loria.fr/~rougier/coding/outdated.html#sdl-terminal"
SRC_URI="http://www.loria.fr/~rougier/pub/Software/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="static-libs"

DEPEND="virtual/opengl
	>=media-libs/libsdl-1.2.4
	media-libs/sdl-ttf"

S=${WORKDIR}/${MY_P}

DOCS=( AUTHORS ChangeLog README )
PATCHES=( "${FILESDIR}"/${P}-python-libs-path.patch )

src_configure() {
	econf $(use_enable static-libs static)
}

src_install() {
	default
	use static-libs || prune_libtool_files
}
