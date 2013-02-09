# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libpng/libpng-1.2.50.ebuild,v 1.6 2012/11/14 14:12:30 jlec Exp $

# this ebuild is only for the libpng12.so.0 SONAME for ABI compat

EAPI=4

inherit multilib libtool

DESCRIPTION="Portable Network Graphics library"
HOMEPAGE="http://www.libpng.org/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.xz"

LICENSE="libpng"
SLOT="1.2"
KEYWORDS="~alpha amd64 arm ~hppa ia64 m68k ~mips ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd ~amd64-linux ~x86-linux"
IUSE=""

RDEPEND="sys-libs/zlib
	!=media-libs/libpng-1.2*:0"
DEPEND="${RDEPEND}
	app-arch/xz-utils"

src_prepare() {
	elibtoolize
}

src_configure() {
	econf --disable-static
}

src_compile() {
	emake libpng12.la
}

src_install() {
	newlib.so .libs/libpng12.so.0.* libpng12.so.0
}
