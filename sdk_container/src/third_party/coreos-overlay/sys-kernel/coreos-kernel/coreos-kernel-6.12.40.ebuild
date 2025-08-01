# Copyright 2014-2016 CoreOS, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI=8
COREOS_SOURCE_REVISION=""
inherit coreos-kernel toolchain-funcs

DESCRIPTION="CoreOS Linux kernel"
KEYWORDS="amd64 arm64"
RESTRICT="userpriv" # dracut (via bootengine) needs root

RDEPEND="=sys-kernel/coreos-modules-${PVR}"
BDEPEND="
	sys-kernel/dracut
"
DEPEND="
	${RDEPEND}
	${BDEPEND}
	app-alternatives/awk
	app-alternatives/gzip
	app-arch/xz-utils
	app-arch/zstd
	app-crypt/clevis
	app-shells/bash
	coreos-base/afterburn
	coreos-base/coreos-init:=
	sys-apps/azure-vm-utils[dracut]
	sys-apps/baselayout
	sys-apps/coreutils
	sys-apps/findutils
	sys-apps/grep
	sys-apps/ignition:=
	sys-apps/iproute2
	sys-apps/less
	sys-apps/nvme-cli
	sys-apps/sed
	sys-apps/shadow
	sys-apps/systemd[cryptsetup]
	sys-apps/seismograph
	sys-apps/util-linux[cryptsetup,udev]
	sys-block/open-iscsi
	sys-fs/btrfs-progs
	sys-fs/cryptsetup[udev]
	sys-fs/e2fsprogs
	sys-fs/lvm2[udev]
	sys-fs/mdadm
	sys-fs/xfsprogs
	>=sys-kernel/bootengine-0.0.38-r37:=
	>=sys-kernel/coreos-firmware-20180103-r1:=
	virtual/udev
	amd64? ( sys-firmware/intel-microcode:= )
"

src_prepare() {
	# Fail early if we didn't detect the build installed by coreos-modules
	[[ -n "${KV_OUT_DIR}" ]] || die "Failed to detect modules build tree"

	default

	# KV_OUT_DIR points to the minimal build tree installed by coreos-modules
	# Pull in the config and public module signing key
	KV_OUT_DIR="${ESYSROOT}/lib/modules/${COREOS_SOURCE_NAME#linux-}/build"
	cp -v "${KV_OUT_DIR}/.config" build/ || die
	validate_sig_key

	config_update 'CONFIG_INITRAMFS_SOURCE="bootengine.cpio"'
	config_update "CONFIG_SYSTEM_TRUSTED_KEYS=\"/usr/share/sb_keys/shim.pem\""

	# include all intel and amd microcode files, avoiding the signatures
	local fw_dir="${ESYSROOT}/lib/firmware"
	use amd64 && config_update "CONFIG_EXTRA_FIRMWARE=\"$(find ${fw_dir} -type f \
		\( -path ${fw_dir}'/intel-ucode/*' -o -path ${fw_dir}'/amd-ucode/*' \) -printf '%P ')\""
	use amd64 && config_update "CONFIG_EXTRA_FIRMWARE_DIR=\"${fw_dir}\""
}

src_compile() {
	local BE_ARGS=()

	if [[ -n ${SYSROOT} ]]; then
		BE_ARGS+=( -r "${SYSROOT}" )
		export DRACUT_ARCH="${CHOST%%-*}"

		# We may need to run ldconfig via QEMU, so use the wrapper. Dracut calls
		# it with -r, which chroots and confuses the sandbox, so calm it down.
		export DRACUT_LDCONFIG="${CHOST}-ldconfig"
		local f; for f in /etc/ld.so.cache{,~} /var/cache/ldconfig/aux-cache{,~}; do
			addwrite "${f}"
		done
	fi

	tc-export PKG_CONFIG
	"${ESYSROOT}"/usr/bin/update-bootengine -k "${KV_FULL}" -o "${S}"/build/bootengine.cpio "${BE_ARGS[@]}" || die
	kmake "$(kernel_target)"

	# sanity check :)
	[[ -e build/certs/signing_key.pem ]] && die "created a new key!"
}

src_install() {
	# coreos-postinst expects to find the kernel in /usr/boot
	insinto "/usr/boot"
	newins "$(kernel_path)" "vmlinuz-${KV_FULL}"
	dosym "vmlinuz-${KV_FULL}" "/usr/boot/vmlinuz"

	insinto "/usr/lib/modules/${KV_FULL}/build"
	doins build/System.map

	insinto "/usr/lib/debug/usr/boot"
	newins build/vmlinux "vmlinux-${KV_FULL}"
	dosym "../../../boot/vmlinux-${KV_FULL}" "/usr/lib/debug/usr/lib/modules/${KV_FULL}/vmlinux"

	# For easy access to vdso debug symbols in gdb:
	#   set debug-file-directory /usr/lib/debug/usr/lib/modules/${KV_FULL}/vdso/
	kmake INSTALL_MOD_PATH="${ED}/usr/lib/debug/usr" vdso_install
}
