# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libsfml/libsfml-2.0_pre20121126.ebuild,v 1.2 2012/12/03 21:35:25 radhermit Exp $

EAPI=5

inherit cmake-utils eutils

DESCRIPTION="Simple and Fast Multimedia Library (SFML)"
HOMEPAGE="http://sfml.sourceforge.net/ https://github.com/LaurentGomila/SFML"
SRC_URI="http://dev.gentoo.org/~radhermit/dist/${P}.tar.xz"

LICENSE="ZLIB"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug doc examples"

RDEPEND="media-libs/freetype:2
	media-libs/glew
	media-libs/libpng
	media-libs/libsndfile
	media-libs/mesa
	media-libs/openal
	sys-libs/zlib
	virtual/jpeg
	x11-libs/libX11
	x11-libs/libXrandr"
DEPEND="${RDEPEND}
	app-arch/xz-utils
	doc? ( app-doc/doxygen )"

DOCS="readme.txt"

src_prepare() {
	epatch "${FILESDIR}"/${P}-no-docs.patch
	epatch "${FILESDIR}"/${P}-shared-glew.patch

	sed -i "s:DESTINATION .*:DESTINATION /usr/share/doc/${PF}:" \
		doc/CMakeLists.txt || die
}

src_configure() {
	local mycmakeargs=(
		$(cmake-utils_use doc SFML_BUILD_DOC)
	)
	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	if use examples ; then
		docompress -x /usr/share/doc/${PF}/examples
		dodoc -r examples
		find "${ED}"/usr/share/doc/${PF}/examples -name CMakeLists.txt -delete
	fi
}
