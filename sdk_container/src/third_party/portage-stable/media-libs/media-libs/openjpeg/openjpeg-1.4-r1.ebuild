# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/openjpeg/openjpeg-1.4-r1.ebuild,v 1.11 2011/11/13 11:24:33 jlec Exp $

EAPI=4

MY_P="${PN}_v${PV/./_}_sources_r697"

inherit base cmake-utils multilib

DESCRIPTION="An open-source JPEG 2000 codec written in C"
HOMEPAGE="http://code.google.com/p/openjpeg/"
SRC_URI="http://${PN}.googlecode.com/files/${MY_P}.tgz"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="doc test"

RDEPEND="
	media-libs/lcms:2
	media-libs/libpng:0
	media-libs/tiff:0
	sys-libs/zlib
"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )"

S=${WORKDIR}/${MY_P}

PATCHES=(
	"${FILESDIR}/${P}-libpng15.patch"
	"${FILESDIR}/${P}-linking.patch"
	"${FILESDIR}/${P}-pkgconfig.patch"
	"${FILESDIR}/${P}-cmake-stdbool.patch"
)

src_prepare() {
	# drop install of license file
	sed -i -e 's:LICENSE::g' CMakeLists.txt || die

	base_src_prepare
}

src_configure() {
	# in the package dir are only useless modules
	# but might be good for documentation :)
	local mycmakeargs=(
		"-DOPENJPEG_INSTALL_LIB_DIR=$(get_libdir)"
		"-DOPENJPEG_INSTALL_DOC_DIR=share/doc/${PF}"
		"-DOPENJPEG_INSTALL_PACKAGE_DIR=share/doc/${PF}"
		$(cmake-utils_use_build test TESTING)
		$(cmake-utils_use_build doc)
	)

	cmake-utils_src_configure
}
