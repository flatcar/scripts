# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/opencolorio/opencolorio-1.0.7.ebuild,v 1.1 2013/01/16 05:47:02 pinkbyte Exp $

EAPI=4

PYTHON_DEPEND="python? 2"

inherit cmake-utils python vcs-snapshot

DESCRIPTION="A color management framework for visual effects and animation"
HOMEPAGE="http://opencolorio.org/"
SRC_URI="https://github.com/imageworks/OpenColorIO/tarball/v${PV} \
		-> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="doc opengl pdf python sse2 test"

RDEPEND="opengl? (
		media-libs/lcms:2
		>=media-libs/openimageio-1.1.0
		media-libs/glew
		media-libs/freeglut
		virtual/opengl
		)
	dev-cpp/yaml-cpp
	dev-libs/tinyxml
	"
DEPEND="${RDEPEND}
	doc? (
		pdf? ( dev-python/sphinx[latex] )
		!pdf? ( dev-python/sphinx )
	)
	"

# Documentation building requires Python bindings building
REQUIRED_USE="doc? ( python )"

# Restricting tests, bugs #439790 and #447908
RESTRICT="test"

pkg_setup() {
	if use python; then
		python_set_active_version 2
		python_pkg_setup
	fi
}

src_prepare() {
	epatch \
		"${FILESDIR}"/${PN}-use-system-libs.patch \
		"${FILESDIR}"/${P}-documentation-gen.patch \
		"${FILESDIR}"/${PN}-openimageio.patch
}

src_configure() {
	# Missing features:
	# - Truelight and Nuke are not in portage for now, so their support are disabled
	# - Java bindings was not tested, so disabled
	# Notes:
	# - OpenImageIO is required for building ociodisplay and ocioconvert (USE opengl)
	# - OpenGL, GLUT and GLEW is required for building ociodisplay (USE opengl)
	local mycmakeargs=(
		-DOCIO_BUILD_JNIGLUE=OFF
		-DOCIO_BUILD_NUKE=OFF
		-DOCIO_BUILD_SHARED=ON
		-DOCIO_BUILD_STATIC=OFF
		-DOCIO_STATIC_JNIGLUE=OFF
		-DOCIO_BUILD_TRUELIGHT=OFF
		$(cmake-utils_use doc OCIO_BUILD_DOCS)
		$(cmake-utils_use opengl OCIO_BUILD_APPS)
		$(cmake-utils_use pdf OCIO_BUILD_PDF_DOCS)
		$(cmake-utils_use python OCIO_BUILD_PYGLUE)
		$(cmake-utils_use sse2 OCIO_USE_SSE)
		$(cmake-utils_use test OCIO_BUILD_TESTS)
	)
	cmake-utils_src_configure
}
