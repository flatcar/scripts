# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/jbigkit/jbigkit-2.0-r1.ebuild,v 1.14 2012/04/26 20:30:05 aballier Exp $

EAPI=4

inherit eutils multilib toolchain-funcs

DESCRIPTION="data compression algorithm for bi-level high-resolution images"
HOMEPAGE="http://www.cl.cam.ac.uk/~mgk25/jbigkit/"
SRC_URI="http://www.cl.cam.ac.uk/~mgk25/download/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="static-libs"

S=${WORKDIR}/${PN}

src_prepare() {
	epatch \
		"${FILESDIR}"/${P}-r1-build.patch \
		"${FILESDIR}"/${P}-static-libs.patch
}

src_compile() {
	tc-export AR CC RANLIB
	emake LIBDIR="${EPREFIX}/usr/$(get_libdir)"
	if use static-libs; then
		cd libjbig && make static
	fi
}

src_test() {
	LD_LIBRARY_PATH=${S}/libjbig make -j1 test
}

src_install() {
	dobin pbmtools/jbgtopbm{,85} pbmtools/pbmtojbg{,85}
	doman pbmtools/jbgtopbm.1 pbmtools/pbmtojbg.1

	insinto /usr/include
	doins libjbig/*.h
	dolib libjbig/libjbig{,85}$(get_libname)
	use static-libs && dolib libjbig/libjbig{,85}.a

	dodoc ANNOUNCE CHANGES TODO libjbig/*.txt
}
