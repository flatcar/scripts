# Copyright (c) 2014 NIFTY Corp.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="OEM suite for NIFTY Cloud images"
HOMEPAGE=""
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

# no source directory
S="${WORKDIR}"

DEPEND="
	app-emulation/open-vm-tools
	"
RDEPEND="${DEPEND}"

src_prepare() {
	default
	sed -e "s\\@@OEM_VERSION_ID@@\\${PVR}\\g" \
	    "${FILESDIR}/cloud-config.yml" > "${T}/cloud-config.yml" || die
}

src_install() {
	into "/usr/share/oem"
	dobin "${FILESDIR}/niftycloud-ssh-key"
	dobin "${FILESDIR}/niftycloud-coreos-cloudinit"
	dobin "${FILESDIR}/flatcar-setup-environment"

	insinto "/usr/share/oem"
	doins "${T}/cloud-config.yml"
	doins "${FILESDIR}/grub.cfg"
}
