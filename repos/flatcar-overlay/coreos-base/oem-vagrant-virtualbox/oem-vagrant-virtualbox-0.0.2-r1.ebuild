# Copyright 2017 The CoreOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="OEM suite for vagrant images (virtualbox)"
HOMEPAGE=""
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

# no source directory
S="${WORKDIR}"

src_install() {
	insinto "/oem"
	doins -r "${FILESDIR}/box"
	doins "${FILESDIR}/grub.cfg"
}
