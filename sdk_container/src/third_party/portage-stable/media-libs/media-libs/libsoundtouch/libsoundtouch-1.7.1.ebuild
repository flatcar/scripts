# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libsoundtouch/libsoundtouch-1.7.1.ebuild,v 1.1 2013/01/03 05:50:52 radhermit Exp $

EAPI=5
inherit autotools eutils flag-o-matic

MY_PN=${PN/lib}

DESCRIPTION="Audio processing library for changing tempo, pitch and playback rates."
HOMEPAGE="http://www.surina.net/soundtouch/"
SRC_URI="http://www.surina.net/soundtouch/${P/lib}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~arm ~hppa ~mips ~ppc ~ppc64 ~x86"
IUSE="sse2 static-libs"

DEPEND="virtual/pkgconfig"

S=${WORKDIR}/${MY_PN}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.7.0-flags.patch
	sed -i -e "s:^\(pkgdoc_DATA=\)COPYING.TXT :\1:" Makefile.am || die
	eautoreconf
}

src_configure() {
	econf \
		--enable-shared \
		--disable-integer-samples \
		--enable-x86-optimizations=$(usex sse2) \
		$(use_enable static-libs static)
}

src_compile() {
	emake CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}"
}

src_install() {
	emake DESTDIR="${D}" pkgdocdir="${EPREFIX}"/usr/share/doc/${PF}/html install
	prune_libtool_files
}
