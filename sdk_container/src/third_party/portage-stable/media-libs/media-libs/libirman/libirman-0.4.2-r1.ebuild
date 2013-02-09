# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libirman/libirman-0.4.2-r1.ebuild,v 1.15 2012/09/14 17:33:11 axs Exp $

inherit eutils toolchain-funcs

DESCRIPTION="library for Irman control of Unix software"
SRC_URI="http://www.lirc.org/software/snapshots/${P}.tar.gz"
HOMEPAGE="http://www.evation.com/libirman/libirman.html"

SLOT="0"
LICENSE="GPL-2 LGPL-2"
KEYWORDS="amd64 ppc ppc64 x86"
IUSE=""

src_unpack() {
	unpack ${A}

	cd "${S}"
	epatch "${FILESDIR}/${P}-PICShared.patch"
	epatch "${FILESDIR}/${P}-destdir.patch"
	epatch "${FILESDIR}/${P}-format.patch"
	epatch "${FILESDIR}/${P}-gcc4.patch"
}

src_compile() {
	tc-export CC LD AR RANLIB

	econf || die "econf failed"
	emake -j1 || die "emake failed"
}

src_install() {
	dodir /usr/include

	make DESTDIR="${D}" \
		LIRC_DRIVER_DEVICE="${D}/dev/lirc" \
		install || die

	dobin test_func test_io test_name
	dodoc NEWS README* TECHNICAL TODO
}
