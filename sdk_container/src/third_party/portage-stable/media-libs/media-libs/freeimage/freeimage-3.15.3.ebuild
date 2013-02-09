# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/freeimage/freeimage-3.15.3.ebuild,v 1.5 2012/07/24 11:50:26 tupone Exp $

EAPI=3

inherit toolchain-funcs eutils multilib

MY_PN=FreeImage
MY_PV=${PV//.}
MY_P=${MY_PN}${MY_PV}

DESCRIPTION="Image library supporting many formats"
HOMEPAGE="http://freeimage.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${MY_P}.zip
	mirror://sourceforge/${PN}/${MY_P}.pdf"

LICENSE="|| ( GPL-2 FIPL-1.0 )"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND="sys-libs/zlib
	media-libs/libpng
	media-libs/libmng
	virtual/jpeg
	media-libs/openjpeg
	media-libs/tiff
	media-libs/libraw
	media-libs/openexr"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	app-arch/unzip"

S="${WORKDIR}"/${MY_PN}

src_prepare() {
	cd Source
	cp LibJPEG/{transupp.c,transupp.h,jinclude.h} . \
		|| die "Failed copying jpeg utility files"
	cp LibTIFF4/{tiffiop,tif_dir}.h . \
		|| die "Failed copying private libtiff files"
	rm -rf LibPNG LibMNG LibOpenJPEG ZLib OpenEXR LibRawLite LibTIFF4 LibJPEG \
		|| die "Removing bundled libraries"
	edos2unix *.h */*.cpp
	cd ..
	edos2unix Makefile.{gnu,fip,srcs} fipMakefile.srcs
	sed -i \
		-e "s:/./:/:g" \
		-e "s: ./: :g" \
		-e 's: Source: \\\n\tSource:g' \
		-e 's: Wrapper: \\\n\tWrapper:g' \
		-e 's: Examples: \\\n\tExamples:g' \
		-e 's: TestAPI: \\\n\tTestAPI:g' \
		-e 's: -ISource: \\\n\t-ISource:g' \
		-e 's: -IWrapper: \\\n\t-IWrapper:g' \
		Makefile.srcs \
		fipMakefile.srcs \
		|| die "sed 1 Failed"
	sed -i \
		-e "/LibJPEG/d" \
		-e "/LibPNG/d" \
		-e "/LibTIFF/d" \
		-e "/Source\/ZLib/d" \
		-e "/LibOpenJPEG/d" \
		-e "/OpenEXR/d" \
		-e "/LibRawLite/d" \
		-e "/LibMNG/d" \
		Makefile.srcs \
		fipMakefile.srcs \
		|| die "sed 1 Failed"
	epatch "${FILESDIR}"/${P}-unbundling.patch
}

src_compile() {
	emake -f Makefile.gnu \
		CXX="$(tc-getCXX) -fPIC" \
		CC="$(tc-getCC) -fPIC" \
		${MY_PN} \
		|| die "emake gnu failed"
	emake -f Makefile.fip \
		CXX="$(tc-getCXX) -fPIC" \
		CC="$(tc-getCC) -fPIC" \
		${MY_PN} \
		|| die "emake fip failed"
}

src_install() {
	emake -f Makefile.gnu \
		install DESTDIR="${D}" INSTALLDIR="${D}"/usr/$(get_libdir) \
		|| die "emake install failed"
	emake -f Makefile.fip \
		install DESTDIR="${D}" INSTALLDIR="${D}"/usr/$(get_libdir) \
		|| die "emake install failed"
	dosym lib${PN}plus-${PV}.so /usr/$(get_libdir)/lib${PN}plus.so.3
	dosym lib${PN}plus.so.3 /usr/$(get_libdir)/lib${PN}plus.so

	dodoc Whatsnew.txt "${DISTDIR}"/${MY_P}.pdf
}
