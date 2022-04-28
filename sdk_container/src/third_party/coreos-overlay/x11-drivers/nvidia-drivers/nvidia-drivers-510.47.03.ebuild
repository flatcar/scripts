# Copyright (c) 2020 Kinvolk GmbH. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="NVIDIA drivers"
HOMEPAGE=""
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

# no source directory
S="${WORKDIR}"

RDEPEND=""

src_install() {
  insinto "/usr/share/oem"
  doins -r "${FILESDIR}/units"
  exeinto "/usr/share/oem/bin"
  doexe "${FILESDIR}/bin/install-nvidia"
  doexe "${FILESDIR}/bin/setup-nvidia"
}
