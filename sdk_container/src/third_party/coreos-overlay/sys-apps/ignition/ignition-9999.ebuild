# Copyright (c) 2015 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Pre-boot provisioning utility"
HOMEPAGE="https://github.com/coreos/ignition"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/coreos/ignition.git"
	inherit git-r3
else
	SRC_URI="https://github.com/coreos/ignition/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="amd64 arm64"

	PATCHES=(
		"${FILESDIR}"/0001-config-add-ignition-translation.patch
		"${FILESDIR}"/0002-mod-add-flatcar-ignition-0.36.2.patch
		"${FILESDIR}"/0003-config-v3_7-convert-ignition-2.x-to-3.x.patch
		"${FILESDIR}"/0004-internal-prv-cmdline-backport-flatcar-patch.patch
		"${FILESDIR}"/0005-provider-qemu-apply-fw_cfg-patch.patch
		"${FILESDIR}"/0006-internal-disk-fs-ignore-fs-format-mismatches-for-the.patch
		"${FILESDIR}"/0007-VMware-Fix-guestinfo.-.config.data-and-.config.url-v.patch
		"${FILESDIR}"/0008-config-version-handle-configuration-version-1.patch
		"${FILESDIR}"/0009-config-util-add-cloud-init-detection-to-initial-pars.patch
		"${FILESDIR}"/0010-translation-support-OEM-and-oem.patch
		"${FILESDIR}"/0011-internal-exec-stages-mount-Mount-oem.patch
		"${FILESDIR}"/0012-go-mod-vendor.patch
		"${FILESDIR}"/0013-internal-resource-url-Add-a-file-schema-for-local-fi.patch
	)
fi

LICENSE="Apache-2.0"
SLOT="0/${PVR}"

# need util-linux for libblkid at compile time
DEPEND="sys-apps/util-linux"

RDEPEND="
	${DEPEND}
	sys-apps/coreutils
	sys-apps/gptfdisk
	sys-apps/shadow
	sys-apps/systemd
	sys-fs/btrfs-progs
	sys-fs/dosfstools
	sys-fs/e2fsprogs
	sys-fs/mdadm
	sys-fs/xfsprogs
"

src_prepare() {
	default
	find -type f -print0 | xargs -0 sed -i "s:\bgithub\.com/coreos/ignition\b:github.com/flatcar/ignition:g" || die
}

src_compile() {
	ego build \
		-ldflags "-X github.com/flatcar/ignition/v2/internal/version.Raw=${PV} -X github.com/flatcar/ignition/v2/internal/distro.selinuxRelabel=false" \
		"${S}"/internal/main.go
}

src_install() {
	newbin "${S}"/main ${PN}
	dosym -r /usr/bin/${PN} /usr/libexec/${PN}-rmcfg
}
