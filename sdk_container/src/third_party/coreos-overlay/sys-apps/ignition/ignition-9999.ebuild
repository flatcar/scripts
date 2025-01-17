# Copyright (c) 2015 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
EGIT_REPO_URI="https://github.com/coreos/ignition.git"
COREOS_GO_PACKAGE="github.com/flatcar/ignition/v2"
COREOS_GO_GO111MODULE="off"
inherit coreos-go git-r3 systemd udev

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
else
	EGIT_COMMIT="a204f429f13194ae379be9401d49e5241439660b" # v2.20.0
	KEYWORDS="amd64 arm64"
fi

DESCRIPTION="Pre-boot provisioning utility"
HOMEPAGE="https://github.com/coreos/ignition"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0/${PVR}"
IUSE=""

# need util-linux for libblkid at compile time
DEPEND="sys-apps/util-linux"

RDEPEND="
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

RDEPEND+="${DEPEND}"

PATCHES=(
	"${FILESDIR}/0001-sed-s-coreos-flatcar.patch"
	"${FILESDIR}/0002-config-add-ignition-translation.patch"
	"${FILESDIR}/0003-mod-add-flatcar-ignition-0.36.2.patch"
	"${FILESDIR}/0004-sum-go-mod-tidy.patch"
	"${FILESDIR}/0005-vendor-go-mod-vendor.patch"
	"${FILESDIR}/0006-config-v3_6-convert-ignition-2.x-to-3.x.patch"
	"${FILESDIR}/0007-internal-prv-cmdline-backport-flatcar-patch.patch"
	"${FILESDIR}/0008-provider-qemu-apply-fw_cfg-patch.patch"
	"${FILESDIR}/0009-config-3_6-test-add-ignition-2.x-test-cases.patch"
	"${FILESDIR}/0010-internal-disk-fs-ignore-fs-format-mismatches-for-the.patch"
	"${FILESDIR}/0011-VMware-Fix-guestinfo.-.config.data-and-.config.url-v.patch"
	"${FILESDIR}/0012-config-version-handle-configuration-version-1.patch"
	"${FILESDIR}/0013-config-util-add-cloud-init-detection-to-initial-pars.patch"
	"${FILESDIR}/0014-Revert-drop-OEM-URI-support.patch"
	"${FILESDIR}/0015-internal-resource-url-support-btrfs-as-OEM-partition.patch"
	"${FILESDIR}/0016-translation-support-OEM-and-oem.patch"
	"${FILESDIR}/0017-revert-internal-oem-drop-noop-OEMs.patch"
	"${FILESDIR}/0018-docs-Add-re-added-platforms-to-docs-to-pass-tests.patch"
	"${FILESDIR}/0019-usr-share-oem-oem.patch"
	"${FILESDIR}/0020-internal-exec-stages-mount-Mount-oem.patch"
	"${FILESDIR}/0021-support-ionoscloud.patch"
)

src_compile() {
	export GO15VENDOREXPERIMENT="1"
	GO_LDFLAGS="-X github.com/flatcar/ignition/v2/internal/version.Raw=${PV} -X github.com/flatcar/ignition/v2/internal/distro.selinuxRelabel=false" || die
	go_build "${COREOS_GO_PACKAGE}/internal"
}

src_install() {
	newbin ${GOBIN}/internal ${PN}

	exeinto "/usr/libexec"
	newexe ${GOBIN}/internal "${PN}-rmcfg"
}
