# Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="OEM suite for Exoscale"
HOMEPAGE="https://www.exoscale.com/"
S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"

SYSEXT_NAME="Exoscale"

src_install() {
	insinto /usr/share/flatcar
	sed "s:@@OEM_VERSION_ID@@:${PVR}:g" "${FILESDIR}/cloud-config.yml" | newins - cloud-config.yml

	dobin "${FILESDIR}"/{exoscale-{coreos-cloudinit,dhcp,ssh-key},flatcar-setup-environment}
}
