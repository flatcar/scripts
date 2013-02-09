# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/sdl-net/sdl-net-1.2.8.ebuild,v 1.8 2012/04/01 11:12:13 armin76 Exp $

EAPI=2
MY_P=${P/sdl-/SDL_}
DESCRIPTION="Simple Direct Media Layer Network Support Library"
HOMEPAGE="http://www.libsdl.org/projects/SDL_net/index.html"
SRC_URI="http://www.libsdl.org/projects/SDL_net/release/${MY_P}.tar.gz"

LICENSE="ZLIB"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE="static-libs"

DEPEND=">=media-libs/libsdl-1.2.14"

S=${WORKDIR}/${MY_P}

src_configure() {
	econf \
		--disable-dependency-tracking \
		--disable-gui \
		$(use_enable static-libs static)
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc CHANGES README
	if ! use static-libs ; then
		find "${D}" -type f -name '*.la' -exec rm {} + \
			|| die "la removal failed"
	fi
}
