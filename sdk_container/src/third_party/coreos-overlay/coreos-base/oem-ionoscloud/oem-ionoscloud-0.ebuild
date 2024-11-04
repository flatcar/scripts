# Copyright (c) 2013 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="OEM suite for IONOS Cloud"
HOMEPAGE="https://cloud.ionos.com"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"

# no source directory
S="${WORKDIR}"

src_install() {
	insinto "/oem"
	doins "${FILESDIR}/grub.cfg"
	doins "${FILESDIR}/USER_DATA_INJECTION"
}
