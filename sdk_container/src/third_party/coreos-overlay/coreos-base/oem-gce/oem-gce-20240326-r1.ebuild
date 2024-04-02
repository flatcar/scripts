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
    app-admin/google-guest-agent
    app-admin/google-guest-configs
    app-admin/google-osconfig-agent
    app-admin/oslogin
"

OEM_NAME="Google Compute Engine"

src_install() {
	systemd_enable_service timers.target google-oslogin-cache.timer
}
