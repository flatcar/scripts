# Copyright (c) 2025 Flatcar Maintainers. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd tmpfiles

DESCRIPTION="OEM suite for STACKIT"
HOMEPAGE="https://stackit.cloud"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE=""

RDEPEND="
  net-misc/chrony
"

S="${WORKDIR}"

OEM_NAME="STACKIT"

src_install() {
    systemd_install_dropin chronyd.service "${FILESDIR}"/chronyd-overwrite.conf
    systemd_enable_service multi-user.target chronyd.service
    dotmpfiles "${FILESDIR}"/var-chrony.conf
    dotmpfiles "${FILESDIR}"/etc-chrony.conf
    insinto /usr/share/"${PN}"
    doins "${FILESDIR}"/chrony.conf
}
