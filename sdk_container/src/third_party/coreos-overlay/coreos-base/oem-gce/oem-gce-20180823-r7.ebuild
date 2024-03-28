# Copyright (c) 2013 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2
# Copyright (c) 2020 Kinvolk GmbH. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="OEM suite for Google Compute Engine images"
HOMEPAGE="https://cloud.google.com/products/compute-engine/"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

# no source directory
S="${WORKDIR}"

RDEPEND="
    app-emulation/google-compute-engine
"

OEM_NAME="Google Compute Engine"

src_install() {
    systemd_dounit "${FILESDIR}/units/oem-gce.service"
    systemd_dounit "${FILESDIR}/units/oem-gce-enable-oslogin.service"
    systemd_dounit "${FILESDIR}/units/setup-oem.service"
    systemd_install_dropin "multi-user.target" "${FILESDIR}/units/10-oem-gce.conf"
    systemd_enable_service "multi-user.target" "ntpd.service"

    dobin "${FILESDIR}/bin/enable-oslogin"
    dobin "${FILESDIR}/bin/init.sh"

    # These files will be symlinked to /etc via 'setup-oem.service'
    insinto /usr/share/gce/
    doins "${FILESDIR}/files/hosts"
    doins "${FILESDIR}/files/google-cloud-sdk.sh"
}
