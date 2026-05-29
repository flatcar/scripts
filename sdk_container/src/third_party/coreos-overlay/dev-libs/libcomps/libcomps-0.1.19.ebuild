# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )

inherit cmake python-single-r1

DESCRIPTION="Comps XML file manipulation library"
HOMEPAGE="https://github.com/rpm-software-management/libcomps"
SRC_URI="https://github.com/rpm-software-management/libcomps/archive/${PV}/${P}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE="python"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

RESTRICT="test"

RDEPEND="
	dev-libs/expat
	dev-libs/libxml2
	sys-libs/zlib
	python? ( ${PYTHON_DEPS} )
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	virtual/pkgconfig
"

S="${WORKDIR}/${P}/libcomps"

src_prepare() {
	# Disable tests subdirectory to avoid build errors
	sed -i -E '/ADD_SUBDIRECTORY.*(tests|Tests)/Id' CMakeLists.txt || die
	sed -i -E '/ENABLE_TESTING/Id' CMakeLists.txt || die
	
	# Disable docs subdirectory
	sed -i -E '/ADD_SUBDIRECTORY.*docs/Id' src/python/CMakeLists.txt || die
	
	# Uncomment the line that creates the py3-copy target in pycopy.cmake
	sed -i 's|^#add_custom_target(\${pycopy} DEPENDS pycomps)|add_custom_target(\${pycopy} DEPENDS pycomps)|' src/python/pycopy.cmake || die
	
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DPYTHON_DESIRED:STRING=$(usex python 3 OFF)
		-DENABLE_DOCS=OFF
		-DENABLE_TESTS=OFF
		-DCMAKE_SKIP_INSTALL_RPATH=ON
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install
	
	if use python; then
		python_optimize
	fi
}
