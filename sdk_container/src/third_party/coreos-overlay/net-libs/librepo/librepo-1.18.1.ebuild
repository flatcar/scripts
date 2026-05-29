# Copyright 2024-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )

inherit cmake python-single-r1

DESCRIPTION="A library for downloading repository metadata and packages"
HOMEPAGE="https://github.com/rpm-software-management/librepo"
SRC_URI="https://github.com/rpm-software-management/librepo/archive/${PV}/${P}.tar.gz"

LICENSE="LGPL-2.1+"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE="python"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

RDEPEND="
	>=dev-libs/glib-2.66
	>=dev-libs/openssl-1.1.1
	>=net-misc/curl-7.52.0
	>=dev-libs/libxml2-2.9
	>=app-arch/zstd-1.4.0
	app-crypt/gpgme
	python? ( ${PYTHON_DEPS} )
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
"

RESTRICT="test"

src_configure() {
	local mycmakeargs=(
		-DENABLE_TESTS=OFF
		-DENABLE_DOCS=OFF
		-DWITH_ZCHUNK=OFF
		-DPYTHON_DESIRED=$(usex python 3 '')
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install
	
	if use python; then
		python_optimize
	fi
}
