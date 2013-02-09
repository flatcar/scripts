# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/vigra/vigra-1.7.1-r1.ebuild,v 1.13 2012/07/04 09:05:57 jdhore Exp $

EAPI=4

PYTHON_DEPEND="python? 2:2.6"
PYTHON_USE_WITH_OPT="python"
PYTHON_USE_WITH="threads xml"

MY_P=${P}-src

inherit base cmake-utils multilib python

DESCRIPTION="C++ computer vision library with emphasize on customizable algorithms and data structures"
HOMEPAGE="http://hci.iwr.uni-heidelberg.de/vigra/"
SRC_URI="http://hci.iwr.uni-heidelberg.de/vigra/${MY_P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ppc ppc64 ~sparc x86 ~amd64-linux ~x86-linux ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="doc +fftw +hdf5 +jpeg +png +python test +tiff"

RDEPEND="
	dev-libs/boost[python?]
	fftw? ( >=sci-libs/fftw-3 )
	hdf5? ( sci-libs/hdf5 )
	jpeg? ( virtual/jpeg )
	png? ( media-libs/libpng:0 )
	tiff? ( media-libs/tiff:0 )
"
DEPEND="${RDEPEND}
	doc? (
		app-doc/doxygen
		python? ( dev-python/sphinx )
	)
	test? (
		python? ( dev-python/nose )
	)
"

PATCHES=(
	"${FILESDIR}/1.7.1-png-1.5.patch"
	"${FILESDIR}/1.7.1-automagicness.patch"
	"${FILESDIR}/1.7.1-hdf5.patch"
	"${FILESDIR}/1.7.1-gcc4.6.patch"
	"${FILESDIR}/1.7.1-numpy_doc.patch"
	"${FILESDIR}/1.7.1-fix-tests.patch"
	"${FILESDIR}/1.7.1-fix-nosetest.patch"
)

REQUIRED_USE="
	doc? ( hdf5 fftw )
	python? ( hdf5 )
	test? ( hdf5 python fftw )
"

CMAKE_IN_SOURCE_BUILD=1

DOCS=(README.txt)

pkg_setup() {
	python_set_active_version 2
	python_pkg_setup
}

src_prepare() {
	base_src_prepare

	# Don't build nor install API docs when not requested
	use doc || sed -e '/ADD_SUBDIRECTORY(docsrc)/d' -i CMakeLists.txt || die
}

src_configure() {
	local libdir=$(get_libdir)

	# required for ddocdir
	_check_build_dir init
	# vigranumpy needs python and if enabled it ooms
	# doc needs doxygen and python
	# walgrind no use for us since we restrict test
	# $(cmake-utils_use_with valgrind VALGRIND)
	local mycmakeargs=(
		"-DDOCDIR=${CMAKE_BUILD_DIR}/doc"
		"-DLIBDIR_SUFFIX=${libdir/lib}"
		"-DDOCINSTALL=share/doc/${PF}"
		"-DWITH_VALGRIND=OFF"
		$(cmake-utils_use_with python VIGRANUMPY)
		$(cmake-utils_use_with png)
		$(cmake-utils_use_with jpeg)
		$(cmake-utils_use_with tiff)
		$(cmake-utils_use_with fftw FFTW3)
		$(cmake-utils_use_with hdf5)
		$(cmake-utils_use_build test TESTING)
		$(cmake-utils_use test CREATE_CTEST_TARGETS)
		$(cmake-utils_use test AUTOBUILD_TESTS)
	)

	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
	use doc && cmake-utils_src_make doc
}

src_install() {
	cmake-utils_src_install

	# drop useless cmake files from libdir
	rm -rf "${ED}"/usr/$(get_libdir)/${PN}/
}

src_test() { : ; }
# bug 390447

pkg_postinst() {
	use python && python_mod_optimize vigra
}

pkg_postrm() {
	use python && python_mod_cleanup vigra
}
