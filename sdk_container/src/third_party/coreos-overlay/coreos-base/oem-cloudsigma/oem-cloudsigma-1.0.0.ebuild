# Copyright (c) 2015 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="OEM suite for CloudSigma"
HOMEPAGE="https://www.cloudsigma.com/"
S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"

SYSEXT_NAME="CloudSigma"

src_install() {
	insinto /usr/share/flatcar
	sed "s:@@OEM_VERSION_ID@@:${PVR}:g" "${FILESDIR}/cloud-config.yml" | newins - cloud-config.yml
}
