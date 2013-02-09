# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gexiv2/gexiv2-0.4.1.ebuild,v 1.10 2013/02/02 22:47:21 ago Exp $

EAPI=4

inherit versionator multilib toolchain-funcs

MY_PV=$(get_version_component_range 1-2)

DESCRIPTION="gexiv2 is a GObject-based wrapper around the Exiv2 library."
HOMEPAGE="http://trac.yorba.org/wiki/gexiv2/"
SRC_URI="http://www.yorba.org/download/${PN}/${MY_PV}/lib${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc x86"
IUSE="static-libs"

RDEPEND="
	dev-libs/glib:2
	>=media-gfx/exiv2-0.21"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

S=${WORKDIR}/lib${P}

src_prepare() {
	tc-export CXX
	sed -e 's:CFLAGS:CXXFLAGS:g' -i Makefile || die
}

src_configure() {
	./configure --prefix=/usr || die
}

src_install() {
	emake DESTDIR="${D}" LIB="$(get_libdir)" install
	dodoc AUTHORS NEWS README THANKS

	use static-libs || find "${D}" \( -name '*.a' -or -name '*.la' \) -delete
}
