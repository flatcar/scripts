#
# Copyright 2021 Google LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

EAPI=7

inherit udev

DESCRIPTION="Google Guest Configs"
HOMEPAGE="http://github.com/GoogleCloudPlatform/guest-configs"

SRC_URI="https://github.com/GoogleCloudPlatform/guest-configs/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0 BSD ZLIB"
KEYWORDS="*"
SLOT="0"
IUSE=""

S=${WORKDIR}/guest-configs-${PV}

src_prepare() {
	eapply "${FILESDIR}"/google-guest-configs-20211116.00-sysctl.patch

	eapply_user
}

src_install() {
	exeinto /lib/udev
	doexe "${S}"/src/lib/udev/google_nvme_id

	udev_dorules "${S}"/src/lib/udev/rules.d/65-gce-disk-naming.rules

	insinto /etc/sysctl.d
	doins "${S}"/src/etc/sysctl.d/60-gce-network-security.conf

	exeinto /usr/bin
	doexe "${S}"/src/usr/bin/google_set_multiqueue
	# Flatcar: why don't they install this?
	doexe "${S}"/src/usr/bin/google_optimize_local_ssd
}
