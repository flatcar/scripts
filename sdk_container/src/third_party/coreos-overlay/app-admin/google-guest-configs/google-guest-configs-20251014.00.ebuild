# Copyright 2025 The Flatcar Container Linux Maintainers
# Distributed under the terms of the Apache License 2.0

# This only installs the udev disk rules because the network rules are not
# GCE-specific. The disk rules need to be in the initrd, so we cannot separate
# this package from other platforms by putting it in the GCE OEM image. We could
# split this package in two, but the network rules don't seem essential.

EAPI=8

inherit udev

DESCRIPTION="Configuration and scripts to support the Google Compute Engine guest environment"
HOMEPAGE="http://github.com/GoogleCloudPlatform/guest-configs"
SRC_URI="https://github.com/GoogleCloudPlatform/guest-configs/archive/${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/guest-configs-${PV}"

LICENSE="Apache-2.0 BSD ZLIB"
SLOT="0"
KEYWORDS="amd64"

RDEPEND="
	sys-apps/nvme-cli
"
#	sys-apps/ethtool
#	sys-apps/iproute2

PATCHES=(
#	"${FILESDIR}"/${PN}-20211116.00-sysctl.patch
)

src_install() {
	exeinto "$(get_udevdir)"
	doexe src/lib/udev/google_nvme_id

	udev_dorules src/lib/udev/rules.d/65-gce-disk-naming.rules
#	udev_dorules src/lib/udev/rules.d/75-gce-network.rules

	insinto /etc/sysctl.d
#	doins src/etc/sysctl.d/60-gce-network-security.conf

#	dobin src/usr/bin/google_set_multiqueue
#	dobin src/usr/bin/google_optimize_local_ssd # Already in google-compute-engine
#	dobin src/usr/bin/gce-nic-naming

	insinto /usr/lib/dracut/modules.d
	doins -r src/lib/dracut/modules.d/*
}

pkg_postinst() {
	udev_reload
}

pkg_postrm() {
	udev_reload
}
