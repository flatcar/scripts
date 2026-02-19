# Copyright 2013 The CoreOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="OEM suite for Vagrant"
HOMEPAGE="https://developer.hashicorp.com/vagrant"
S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"

SYSEXT_NAME="Vagrant"

src_install() {
	insinto /usr/share/flatcar
	sed "s:@@OEM_VERSION_ID@@:${PVR}:g" "${FILESDIR}/cloud-config.yml" | newins - cloud-config.yml

	dobin "${FILESDIR}"/flatcar-setup-environment
}
