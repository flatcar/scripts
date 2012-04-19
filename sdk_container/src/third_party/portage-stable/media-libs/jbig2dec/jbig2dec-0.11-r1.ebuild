# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/jbig2dec/jbig2dec-0.11-r1.ebuild,v 1.11 2012/03/18 17:37:53 armin76 Exp $

EAPI=4
inherit autotools eutils

DESCRIPTION="A decoder implementation of the JBIG2 image compression format"
HOMEPAGE="http://jbig2dec.sourceforge.net/"
SRC_URI="http://ghostscript.com/~giles/jbig2/${PN}/${P}.tar.gz
	test? ( http://jbig2dec.sourceforge.net/ubc/jb2streams.zip )"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~alpha amd64 arm ~hppa ~ia64 ~mips ppc ppc64 ~sparc x86 ~x86-fbsd"
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
