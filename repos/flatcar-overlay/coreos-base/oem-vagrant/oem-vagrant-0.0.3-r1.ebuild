# Copyright 2013 The CoreOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="OEM suite for vagrant images"
HOMEPAGE=""
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

# no source directory
S="${WORKDIR}"

src_prepare() {
	default
	sed -e "s\\@@OEM_VERSION_ID@@\\${PVR}\\g" \
	    "${FILESDIR}/cloud-config.yml" > "${T}/cloud-config.yml" || die
}

src_install() {
	insinto "/oem"
	doins "${T}/cloud-config.yml"
	doins -r "${FILESDIR}/box"
	doins "${FILESDIR}/grub.cfg"

	into "/oem"
	dobin "${FILESDIR}/flatcar-setup-environment"
}
