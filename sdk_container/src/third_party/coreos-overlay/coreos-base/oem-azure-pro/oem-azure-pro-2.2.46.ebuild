# Copyright (c) 2013 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="OEM suite for Azure"
HOMEPAGE=""
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

# no source directory
S="${WORKDIR}"

# This source is a superset of oem-azure and implments the pro bits. The source
# of oem-azure-pro is duplicated from oem-azure because making using of RDEPEND
# would result in the conflict of `base.ign`
RDEPEND="
  ~app-emulation/wa-linux-agent-${PV}
  x11-drivers/nvidia-drivers
"

src_prepare() {
	sed -e "s\\@@OEM_VERSION_ID@@\\${PVR}\\g" \
		"${FILESDIR}/oem-release" > "${T}/oem-release" || die
}

src_install() {
	insinto "/usr/share/oem"
	doins "${FILESDIR}/grub.cfg"
	doins "${T}/oem-release"
	doins -r "${FILESDIR}/base"
	doins -r "${FILESDIR}/units"
}
