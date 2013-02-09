# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/lensfun/lensfun-0.2.6.ebuild,v 1.2 2012/09/21 16:19:15 ottxor Exp $

EAPI=4

PYTHON_DEPEND="2:2.6"

inherit cmake-utils multilib python

DESCRIPTION="lensfun: A library for rectifying and simulating photographic lens distortions"
HOMEPAGE="http://lensfun.berlios.de/"
SRC_URI="mirror://berlios/${PN}/${P}.tar.bz2"

LICENSE="LGPL-3 CCPL-Attribution-ShareAlike-3.0" # See README for reasoning.
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-fbsd ~amd64-linux ~x86-linux"
IUSE="doc sse sse2"

RDEPEND=">=dev-libs/glib-2.28
	media-libs/libpng:0
	sys-libs/zlib"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )"

PATCHES=(
	"${FILESDIR}"/${P}-auxfun.patch
	"${FILESDIR}"/${PN}-0.2.5_p153-build.patch
	"${FILESDIR}"/${PN}-0.2.5_p153-pc.patch
	)

DOCS=( README docs/mounts.txt )

pkg_setup() {
	python_set_active_version 2
	python_pkg_setup
}

src_configure() {
	local mycmakeargs=(
		-DDOCDIR="${EPREFIX}"/usr/share/doc/${PF}/html
		-DLIBDIR=$(get_libdir)
		-DBUILD_AUXFUN=ON
		$(cmake-utils_use_build doc)
		$(cmake-utils_use_build sse FOR_SSE)
		$(cmake-utils_use_build sse2 FOR_SSE2)
		-DBUILD_STATIC=OFF
		-DBUILD_TESTS=OFF
		)

	cmake-utils_src_configure
}
