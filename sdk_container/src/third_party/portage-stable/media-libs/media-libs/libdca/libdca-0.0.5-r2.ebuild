# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libdca/libdca-0.0.5-r2.ebuild,v 1.13 2012/05/17 14:14:49 aballier Exp $

EAPI=3
inherit autotools eutils flag-o-matic multilib

DESCRIPTION="library for decoding DTS Coherent Acoustics streams used in DVD"
HOMEPAGE="http://www.videolan.org/developers/libdca.html"
SRC_URI="http://www.videolan.org/pub/videolan/${PN}/${PV}/${P}.tar.bz2
	mirror://gentoo/${P}-constant.patch.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE="debug oss static-libs"

RDEPEND="!media-libs/libdts"
DEPEND="${RDEPEND}"

src_prepare() {
	epatch "${FILESDIR}"/${P}-cflags.patch \
		"${FILESDIR}"/${P}-tests-optional.patch \
		"${WORKDIR}"/${P}-constant.patch

	eautoreconf
}

src_configure() {
	append-lfs-flags #328875

	econf \
		--disable-dependency-tracking \
		$(use_enable debug) \
		$(use_enable static-libs static) \
		$(use_enable oss)
}

src_compile() {
	emake OPT_CFLAGS="" || die
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog NEWS README TODO doc/${PN}.txt

	find "${ED}" -name '*.la' -exec rm -f '{}' +
	rm -f "${ED}"/usr/$(get_libdir)/libdts.a
}
