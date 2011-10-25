# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libjpeg-turbo/libjpeg-turbo-1.1.1.ebuild,v 1.5 2011/06/18 15:41:08 phajdan.jr Exp $

EAPI=4
inherit libtool toolchain-funcs

DESCRIPTION="MMX, SSE, and SSE2 SIMD accelerated JPEG library"
HOMEPAGE="http://libjpeg-turbo.virtualgl.org/ http://sourceforge.net/projects/libjpeg-turbo/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz
	mirror://debian/pool/main/libj/libjpeg8/libjpeg8_8c-1.debian.tar.gz"

LICENSE="as-is LGPL-2.1 wxWinLL-3.1"
SLOT="0"
KEYWORDS="amd64 ~arm x86 ~amd64-linux ~x86-linux"
IUSE="static-libs"

NASM_DEPEND="dev-lang/nasm"
RDEPEND="!media-libs/jpeg:0"
DEPEND="${RDEPEND}
	amd64? ( ${NASM_DEPEND} )
	x86? ( ${NASM_DEPEND} )
	amd64-linux? ( ${NASM_DEPEND} )
	x86-linux? ( ${NASM_DEPEND} )"

DOCS=( BUILDING.txt ChangeLog.txt example.c README-turbo.txt )

src_prepare() {
	elibtoolize
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		--with-jpeg8
}

src_compile() {
	default

	cd ../debian/extra || die
	emake CC="$(tc-getCC)" CFLAGS="${LDFLAGS} ${CFLAGS}"
}

src_test() {
	emake test
}

src_install() {
	default
	find "${D}" -name '*.la' -exec rm -f {} +

	cd ../debian/extra || die
	emake DESTDIR="${D}" prefix="${EPREFIX}/usr" \
		INSTALL="install -m755" INSTALLDIR="install -d -m755" \
		install
}
