# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libharu/libharu-2.2.1-r1.ebuild,v 1.5 2012/07/04 22:12:45 bicatali Exp $

EAPI=4

inherit eutils multilib

DESCRIPTION="C/C++ library for PDF generation"
HOMEPAGE="http://www.libharu.org/"
SRC_URI="http://libharu.org/files/${P}.tar.bz2"

LICENSE="ZLIB"
SLOT="0"
KEYWORDS="amd64 ppc x86 ~amd64-linux ~x86-linux"
IUSE="png static-libs zlib"

DEPEND="
	png? ( media-libs/libpng )
	zlib? ( sys-libs/zlib )"
RDEPEND="${DEPEND}"

src_prepare() {
	epatch "${FILESDIR}"/${P}-libpng-1.5.patch
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(use_with png png "${EPREFIX}"/usr) \
		$(use_with zlib)
}

src_install() {
	emake \
		INSTALL_STRIP_FLAG="" \
		DESTDIR="${D}" install
	dodoc README
	use static-libs || rm -f "${ED}"/usr/$(get_libdir)/libhpdf.la
}
