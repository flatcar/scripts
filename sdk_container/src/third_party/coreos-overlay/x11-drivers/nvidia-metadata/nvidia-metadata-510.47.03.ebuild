# Copyright (c) 2021 Kinvolk GmbH. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="NVIDIA drivers release version and configuration"
HOMEPAGE=""
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE=""

# no source directory
S="${WORKDIR}"

RDEPEND=""

src_install() {
  insinto "/usr/share/flatcar"
  doins "${FILESDIR}/nvidia-metadata"
}
