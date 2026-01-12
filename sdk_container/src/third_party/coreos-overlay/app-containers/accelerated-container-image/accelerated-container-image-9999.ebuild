# Copyright 2025 The Flatcar Container Linux Maintainers
# Distributed under the terms of the Apache License 2.0

EAPI=8

inherit go-module systemd tmpfiles

DESCRIPTION="Remote container image format (overlaybd) and snapshotter based on block-device"
HOMEPAGE="https://github.com/containerd/accelerated-container-image"

if [[ ${PV} == 9999* ]]; then
	EGIT_REPO_URI="https://github.com/containerd/accelerated-container-image.git"
	inherit git-r3
else
	SRC_URI="https://github.com/containerd/accelerated-container-image/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
		https://dev.gentoo.org/~chewi/distfiles/${P}-vendor.tar.xz"
	KEYWORDS="amd64 arm64"
fi

LICENSE="Apache-2.0"
SLOT="0"

RDEPEND="sys-fs/overlaybd"

src_unpack() {
	[[ ${PV} == 9999* ]] && git-r3_src_unpack
	go-module_src_unpack
}

src_install() {
	emake install \
		DESTDIR="${ED}" \
		SN_DESTDIR="${ED}/usr/local/overlaybd/snapshotter" \
		SN_CFGDIR="${ED}/usr/local/overlaybd/snapshotter/etc"

	sed -i 's,/opt/overlaybd,/usr/local/overlaybd,' \
		"${ED}/usr/local/overlaybd/snapshotter/overlaybd-snapshotter.service" || die

	# tmpfiles will take care of symlinking /usr/local/overlaybd/snapshotter
	# to /opt/overlaybd/snapshotter, where upstream expects the binaries.
	# (we need them in /usr to be used in a sysext)
	dotmpfiles "${FILESDIR}/10-overlaybd-snapshotter.conf"

	systemd_dounit "${ED}/usr/local/overlaybd/snapshotter/overlaybd-snapshotter.service"
	systemd_enable_service "multi-user.target" "overlaybd-snapshotter.service"
}
