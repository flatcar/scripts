# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="OEM suite for VMware"
HOMEPAGE="https://github.com/flatcar/coreos-overlay/tree/main/coreos-base"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

DEPEND="
	~app-emulation/open-vm-tools-${PV}
	"
RDEPEND="${DEPEND}"

# no source directory
S="${WORKDIR}"

src_prepare() {
	default
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
