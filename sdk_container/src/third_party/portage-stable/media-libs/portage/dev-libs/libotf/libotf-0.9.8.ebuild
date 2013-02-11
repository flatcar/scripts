# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libotf/libotf-0.9.8.ebuild,v 1.12 2012/05/04 18:35:44 jdhore Exp $

WANT_AUTOMAKE=latest
WANT_AUTOCONF=latest

inherit autotools

DESCRIPTION="Library for handling OpenType fonts (OTF)"
HOMEPAGE="http://www.m17n.org/libotf/"
SRC_URI="http://www.m17n.org/libotf/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sh sparc x86"
IUSE="X"

RDEPEND=">=media-libs/freetype-2.1
	X? (
		x11-libs/libXaw
		x11-libs/libICE
	)"

DEPEND="${RDEPEND}
	>=sys-apps/sed-4
	virtual/pkgconfig"

src_unpack() {
	unpack ${A}
	cd "${S}"
	use X || sed -i -e '/^bin_PROGRAMS/s/otfview//' example/Makefile.am || die
	use X || eautoreconf
}

src_install() {
	emake DESTDIR="${D}" install || die

	dodoc AUTHORS NEWS README ChangeLog
}
