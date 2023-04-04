# Copyright (c) 2015 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_PROJECT="coreos/ignition"
CROS_WORKON_LOCALNAME="ignition"
CROS_WORKON_REPO="https://github.com"
COREOS_GO_PACKAGE="github.com/flatcar/ignition/v2"
COREOS_GO_GO111MODULE="off"
inherit coreos-go cros-workon systemd udev

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
else
	CROS_WORKON_COMMIT="13f05b3c9f6221fb68234387ff2e4c2d63a39b63" # v2.15.0
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
	"${FILESDIR}/0002-mod-add-flatcar-ignition-0.36.2.patch"
	"${FILESDIR}/0003-sum-go-mod-tidy.patch"
	"${FILESDIR}/0004-vendor-go-mod-vendor.patch"
	"${FILESDIR}/0005-config-add-ignition-translation.patch"
	"${FILESDIR}/0006-config-v3_5-convert-ignition-2.x-to-3.x.patch"
	"${FILESDIR}/0007-internal-prv-cmdline-backport-flatcar-patch.patch"
	"${FILESDIR}/0008-provider-qemu-apply-fw_cfg-patch.patch"
	"${FILESDIR}/0009-config-3_5-test-add-ignition-2.x-test-cases.patch"
	"${FILESDIR}/0010-internal-disk-fs-ignore-fs-format-mismatches-for-the.patch"
	"${FILESDIR}/0011-VMware-Fix-guestinfo.-.config.data-and-.config.url-v.patch"
	"${FILESDIR}/0012-config-version-handle-configuration-version-1.patch"
	"${FILESDIR}/0013-config-util-add-cloud-init-detection-to-initial-pars.patch"
	"${FILESDIR}/0014-Revert-drop-OEM-URI-support.patch"
	"${FILESDIR}/0015-internal-resource-url-support-btrfs-as-OEM-partition.patch"
	"${FILESDIR}/0016-internal-exec-stages-disks-prevent-races-with-udev.patch"
	"${FILESDIR}/0017-translation-support-OEM-and-oem.patch"
	"${FILESDIR}/0018-revert-internal-oem-drop-noop-OEMs.patch"
	"${FILESDIR}/0019-docs-Add-re-added-platforms-to-docs-to-pass-tests.patch"
	"${FILESDIR}/0020-usr-share-oem-oem.patch"
	"${FILESDIR}/0021-internal-exec-stages-mount-Mount-oem.patch"
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
