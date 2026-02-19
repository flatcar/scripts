# Copyright (c) 2013 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd tmpfiles

DESCRIPTION="OEM suite for Azure"
HOMEPAGE="https://azure.microsoft.com/"
S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64"

RDEPEND="
  ~app-emulation/wa-linux-agent-${PV}
  app-emulation/hv-daemons
  dev-python/urllib3
  net-misc/chrony
  sys-fs/inotify-tools
"

SYSEXT_NAME="Microsoft Azure"


src_install() {
	systemd_enable_service multi-user.target chronyd.service
	insinto "$(systemd_get_systemunitdir)"/chronyd.service.d
	doins "${FILESDIR}"/chrony-hyperv.conf
	dotmpfiles "${FILESDIR}"/var-chrony.conf
	dotmpfiles "${FILESDIR}"/etc-chrony.conf
	insinto /usr/share/${PN}
	doins "${FILESDIR}"/chrony.conf
}
