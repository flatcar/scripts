# Copyright 2024 Flatcar Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

GIT_COMMIT="1a1167d1d7780068d0af5afc3ad18a2601e951fe"
DESCRIPTION="Azure NVMe utilities"
HOMEPAGE="https://github.com/Azure/azure-nvme-utils"
SRC_URI="https://github.com/Azure/azure-nvme-utils/archive/${GIT_COMMIT}.zip -> ${P}-${GIT_COMMIT}.zip"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 arm64"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""

S="${WORKDIR}/${PN}-${GIT_COMMIT}"

src_configure() {
	local mycmakeargs=(
		-DVERSION="${PVR}-${GIT_COMMIT}"
	)
	cmake_src_configure
}
