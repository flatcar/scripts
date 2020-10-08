# Copyright (c) 2020 Kinvolk GmbH. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="OEM suite for QEMU"
HOMEPAGE=""
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE=""

# no source directory
S="${WORKDIR}"

src_prepare() {
	sed -e "s\\@@OEM_VERSION_ID@@\\${PVR}\\g" \
		"${FILESDIR}/oem-release" > "${T}/oem-release" || die
}

src_install() {
	insinto "/usr/share/oem"
	doins "${FILESDIR}/grub.cfg"
	doins "${T}/oem-release"
}

