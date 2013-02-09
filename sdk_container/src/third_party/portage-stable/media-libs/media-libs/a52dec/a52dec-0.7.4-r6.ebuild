# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/a52dec/a52dec-0.7.4-r6.ebuild,v 1.18 2012/05/17 13:55:59 aballier Exp $

EAPI=3
inherit autotools eutils flag-o-matic

DESCRIPTION="library for decoding ATSC A/52 streams used in DVD"
HOMEPAGE="http://liba52.sourceforge.net/"
SRC_URI="http://liba52.sourceforge.net/files/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE="djbfft oss static-libs"

RDEPEND="djbfft? ( sci-libs/djbfft )"
DEPEND="${RDEPEND}"

src_prepare() {
	epatch \
		"${FILESDIR}"/${P}-build.patch \
		"${FILESDIR}"/${P}-freebsd.patch \
		"${FILESDIR}"/${P}-tests-optional.patch \
		"${FILESDIR}"/${P}-test-hidden-symbols.patch

	eautoreconf
	epunt_cxx
}

src_configure() {
	filter-flags -fprefetch-loop-arrays

	local myconf
	use oss || myconf="${myconf} --disable-oss"

	econf \
		--enable-shared \
		$(use_enable static-libs static) \
		$(use_enable djbfft) \
		${myconf}
}

src_compile() {
	emake CFLAGS="${CFLAGS}" || die
}

src_install() {
	emake DESTDIR="${D}" install || die

	insinto /usr/include/a52dec
	doins liba52/a52_internal.h || die

	dodoc AUTHORS ChangeLog HISTORY NEWS README TODO doc/liba52.txt

	find "${ED}" -name '*.la' -exec rm -f {} +
}
