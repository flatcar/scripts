# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/jbig2dec/jbig2dec-0.11-r1.ebuild,v 1.21 2012/08/09 17:21:08 grobian Exp $

EAPI=4
inherit autotools eutils

DESCRIPTION="A decoder implementation of the JBIG2 image compression format"
HOMEPAGE="http://jbig2dec.sourceforge.net/"
SRC_URI="http://ghostscript.com/~giles/jbig2/${PN}/${P}.tar.gz
	test? ( http://jbig2dec.sourceforge.net/ubc/jb2streams.zip )"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~x86-solaris"
IUSE="png static-libs test"

RDEPEND="png? ( >=media-libs/libpng-1.2:0 )"
DEPEND="${RDEPEND}
	test? ( app-arch/unzip )"

RESTRICT="test"
# bug 324275

DOCS="CHANGES README"

src_prepare() {
	epatch "${FILESDIR}"/${P}-libpng15.patch
	eautoreconf

	if use test; then
		mkdir "${WORKDIR}/ubc" || die
		mv -v "${WORKDIR}"/*.jb2 "${WORKDIR}/ubc/" || die
		mv -v "${WORKDIR}"/*.bmp "${WORKDIR}/ubc/" || die
	fi
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(use_with png libpng)
}

src_install() {
	default
	find "${ED}" -name '*.la' -exec rm -f {} +
}
