# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libmng/libmng-1.0.10-r1.ebuild,v 1.11 2012/12/16 16:16:01 ulm Exp $

EAPI=3
inherit autotools

DESCRIPTION="Multiple Image Networkgraphics lib (animated png's)"
HOMEPAGE="http://www.libmng.com/"
SRC_URI="mirror://sourceforge/libmng/${P}.tar.gz"

LICENSE="libmng"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="lcms static-libs"

RDEPEND="virtual/jpeg
	>=sys-libs/zlib-1.1.4
	lcms? ( =media-libs/lcms-1* )"
DEPEND="${RDEPEND}"

src_prepare() {
	ln -s makefiles/configure.in .
	ln -s makefiles/Makefile.am .
	sed -i '/^AM_C_PROTOTYPES$/d' configure.in || die #420223

	eautoreconf
}

src_configure() {
	econf \
		--disable-dependency-tracking \
		$(use_enable static-libs static) \
		--with-jpeg \
		$(use_with lcms)
}

src_install() {
	emake DESTDIR="${D}" install || die

	use static-libs || find "${ED}" -name '*.la' -exec rm -f {} +

	dodoc CHANGES README*
	dodoc doc/doc.readme doc/libmng.txt
	doman doc/man/*
}
