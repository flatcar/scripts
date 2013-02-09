# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/gexiv2/gexiv2-0.2.1.ebuild,v 1.3 2012/05/05 08:02:25 jdhore Exp $

EAPI=2
inherit versionator eutils multilib toolchain-funcs

MY_PV=$(get_version_component_range 1-2)

DESCRIPTION="gexiv2 is a GObject-based wrapper around the Exiv2 library."
HOMEPAGE="http://trac.yorba.org/wiki/gexiv2"
SRC_URI="http://www.yorba.org/download/${PN}/${MY_PV}/lib${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND=">=media-gfx/exiv2-0.19
	dev-libs/glib:2"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

S=${WORKDIR}/lib${P}

src_prepare() {
	epatch "${FILESDIR}"/${P}-new-exiv2.patch
}

src_configure() {
	tc-export CXX
	./configure --prefix=/usr || die
}

src_install() {
	emake DESTDIR="${D}" LIB="$(get_libdir)" install || die
	dodoc AUTHORS NEWS README THANKS

	find "${D}" -name '*.la' -exec rm -f '{}' +
}
