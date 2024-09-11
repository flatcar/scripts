# Copyright (c) 2013 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd tmpfiles

DESCRIPTION="OEM suite for Azure"
HOMEPAGE="https://azure.microsoft.com/"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE=""

RDEPEND="
  ~app-emulation/wa-linux-agent-${PV}
  net-misc/chrony
  app-emulation/hv-daemons
"

# for coreos-base/common-oem-files
OEM_NAME="Microsoft Azure"

S="${WORKDIR}"

src_install() {
	systemd_enable_service multi-user.target chronyd.service
	insinto "$(systemd_get_systemunitdir)"/chronyd.service.d
	doins "${FILESDIR}"/chrony-hyperv.conf
	dotmpfiles "${FILESDIR}"/var-chrony.conf
	dotmpfiles "${FILESDIR}"/etc-chrony.conf
	insinto /usr/share/${PN}
	doins "${FILESDIR}"/chrony.conf
}
