# Copyright 2024-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Library for solving packages and reading repositories"
HOMEPAGE="https://github.com/openSUSE/libsolv"
SRC_URI="https://github.com/openSUSE/libsolv/archive/${PV}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0/1"
KEYWORDS="amd64 arm64"
IUSE="+comps +rpm"

RDEPEND="
	sys-libs/zlib
	app-arch/zstd
	comps? ( dev-libs/libxml2 )
	rpm? ( >=app-arch/rpm-4.14.0 )
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

src_configure() {
	local mycmakeargs=(
		-DENABLE_COMPS=$(usex comps ON OFF)
		-DENABLE_RPMDB=$(usex rpm ON OFF)
		-DENABLE_RPMDB_BYRPMHEADER=$(usex rpm ON OFF)
		-DENABLE_RPMMD=$(usex rpm ON OFF)
		-DENABLE_COMPLEX_DEPS=ON
		-DENABLE_ZSTD_COMPRESSION=ON
		-DENABLE_ZCHUNK_COMPRESSION=OFF
	)
	cmake_src_configure
}
