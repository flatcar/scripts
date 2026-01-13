# Copyright 2026 The Flatcar Container Linux Maintainers
# Distributed under the terms of the Apache License 2.0

# IMPORTANT! When bumping, ensure that the Dracut modules do not install files
# that would make runtime changes to systems to other than GCE VMs because the
# initrd is shared between image types. The udev disk rules are currently safe.

EAPI=8

inherit udev

DESCRIPTION="Configuration and scripts to support the Google Compute Engine guest environment"
HOMEPAGE="http://github.com/GoogleCloudPlatform/guest-configs"
SRC_URI="https://github.com/GoogleCloudPlatform/guest-configs/archive/${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/guest-configs-${PV}"

LICENSE="Apache-2.0 BSD ZLIB"
SLOT="0"
KEYWORDS="amd64"
IUSE="flatcar-oem"

RDEPEND="
	!<app-emulation/google-compute-engine-20190124-r3
	sys-apps/nvme-cli
	flatcar-oem? (
		net-misc/curl
		sys-apps/ethtool
		sys-apps/iproute2
	)
"

PATCHES=(
	"${FILESDIR}"/${PN}-20211116.00-sysctl.patch
	"${FILESDIR}"/${PN}-dracut-deps.patch
)

src_install() {
	exeinto "$(get_udevdir)"
	doexe src/lib/udev/google_nvme_id

	udev_dorules src/lib/udev/rules.d/65-gce-disk-naming.rules

	insinto /usr/lib/dracut/modules.d
	doins -r src/lib/dracut/modules.d/*

	# We want the above files available before the OEM sysext is mounted.
	# Anything below here only goes into the sysext.
	use flatcar-oem || return

	udev_dorules src/lib/udev/rules.d/75-gce-network.rules

	insinto /usr/lib/sysctl.d
	doins src/etc/sysctl.d/60-gce-network-security.conf

	dobin src/usr/bin/google_set_multiqueue
	dobin src/usr/bin/google_optimize_local_ssd
	dobin src/usr/bin/gce-nic-naming
}

pkg_postinst() {
	udev_reload
}

pkg_postrm() {
	udev_reload
}
