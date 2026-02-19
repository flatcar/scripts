# Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="OEM suite for CloudStack"
HOMEPAGE="https://cloudstack.apache.org/"
S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"

SYSEXT_NAME="CloudStack"

src_install() {
	insinto /usr/share/flatcar
	sed "s:@@OEM_VERSION_ID@@:${PVR}:g" "${FILESDIR}/cloud-config.yml" | newins - cloud-config.yml

	dobin "${FILESDIR}"/{cloudstack-{coreos-cloudinit,dhcp,ssh-key},flatcar-setup-environment}
}
