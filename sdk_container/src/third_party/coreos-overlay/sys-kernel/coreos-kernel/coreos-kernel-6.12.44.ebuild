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
	sys-apps/busybox
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

	# include all intel and amd microcode files, avoiding the signatures
	local fw_dir="${ESYSROOT}/lib/firmware"
	use amd64 && config_update "CONFIG_EXTRA_FIRMWARE=\"$(find ${fw_dir} -type f \
		\( -path ${fw_dir}'/intel-ucode/*' -o -path ${fw_dir}'/amd-ucode/*' \) -printf '%P ')\""
	use amd64 && config_update "CONFIG_EXTRA_FIRMWARE_DIR=\"${fw_dir}\""
}

copy_in() {
  # Simple setup, assume we only have /lib64 to care about
  cp "${ESYSROOT}"/usr/"$1" ./"$1"
  for LIBFILE in $(patchelf --print-needed ./"$1"); do
    if [ ! -e ./lib64/"${LIBFILE}" ]; then
      copy_in /lib64/"${LIBFILE}"
    fi
  done
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
	# Copy full initrd over to /usr as filesystem image
	mkdir "${S}"/build/bootengine || die
	pushd "${S}"/build/bootengine || die
	sudo lsinitrd --unpack "${S}"/build/bootengine.cpio || die
	sudo mksquashfs . "${S}"/build/bootengine.img -noappend -xattrs-exclude ^btrfs. || die
	popd || die
	# Create minimal initrd
	microcode=$(cpio -t < "${S}"/build/bootengine.cpio 2>&1 > /dev/null | cut -d " " -f 1)
	# Only keep early cpio for microcode
	truncate -s $((microcode*512)) "${S}"/build/bootengine.cpio || die
	# Debug: List contents after truncation
	cpio -t < "${S}"/build/bootengine.cpio
	mkdir "${S}"/build/minimal || die
	pushd "${S}"/build/minimal || die
	mkdir -p {etc,bin,sbin,dev,proc,sys,dev,lib,lib64,usr/bin,usr/sbin,usr/lib,usr/lib64,realinit,sysusr/usr}
	mkdir -p lib/modules/"${KV_FULL}"/
	cp "${ESYSROOT}"/usr/lib/modules/"${KV_FULL}"/modules.* lib/modules/"${KV_FULL}"/
	mkdir -p lib/modprobe.d/
	cp "${ROOTFS}"/lib/modprobe.d/* lib/modprobe.d/
	# TODO: the hard part: what to include (networking is out of scope)
	MODULES=("fs/overlayfs" "fs/squashfs" "drivers/block/loop.ko.xz" "fs/btrfs" "drivers/nvme" "drivers/scsi" "drivers/ata" "drivers/block" "drivers/char/virtio_console.ko.xz" "drivers/hv" "drivers/input/serio" "drivers/mmc" "drivers/usb" "drivers/hid")
	for MODULE in "${MODULES[@]}"; do
		if [ -f "${ESYSROOT}"/usr/lib/modules/"${KV_FULL}"/kernel/"${MODULE}" ]; then
			MODULE_DIR=$(dirname "${MODULE}")
			mkdir -p lib/modules/"${KV_FULL}"/kernel/"${MODULE_DIR}"
			cp "${ESYSROOT}"/usr/lib/modules/"${KV_FULL}"/kernel/"${MODULE}" lib/modules/"${KV_FULL}"/kernel/"${MODULE}"
		elif [ -d "${ESYSROOT}"/usr/lib/modules/"${KV_FULL}"/kernel/"${MODULE}" ]; then
			mkdir -p lib/modules/"${KV_FULL}"/kernel/"${MODULE}"
			cp -r "${ESYSROOT}"/usr/lib/modules/"${KV_FULL}"/kernel/"${MODULE}"/* lib/modules/"${KV_FULL}"/kernel/"${MODULE}"/
		else
			die "wrong module type/not found: ${ESYSROOT}"/usr/lib/modules/"${KV_FULL}"/kernel/"${MODULE}"
		fi
	done
	for MODULE in $(find ./lib/modules/"${KV_FULL}"/ -type f); do
		MODULE=$(basename "${MODULE}" | sed "s/\.ko\.xz$//")
		for DEP in $(modprobe -S "${KV_FULL}" -d "${ESYSROOT}" -D "${MODULE}" | grep "^insmod " | sed "s/^insmod //"); do
			DEP=$(echo "${DEP}" | sed "s,${ESYSROOT},/,")
			DEP_DIR=$(dirname "${DEP}")
			mkdir -p ./"${DEP_DIR}"
			cp "${ESYSROOT}"/"${DEP}" ./"${DEP}"
		done
	done
	echo '$MODALIAS=.*	0:0 660 @/sbin/modprobe "$MODALIAS"' > ./etc/mdev.conf
	copy_in /bin/veritysetup
	copy_in /bin/busybox
	# We can't use busybox's modprobe because it doesn't support the globs in module.alias, breaking module loading
	copy_in /sbin/kmod
	ln -s /sbin/kmod ./sbin/modprobe
	cp -a "${ESYSROOT}"/usr/bin/minimal-init ./init
	# Make it easier to debug by not relying too much on the first commands
	ln -s /bin/busybox ./bin/sh
	mknod ./dev/console c 5 1
	mknod ./dev/null c 1 3
	mknod ./dev/tty c 5 0
	mknod ./dev/urandom c 1 9
	mknod ./dev/random c 1 8
	mknod ./dev/zero c 1 5
	# No compression because CONFIG_INITRAMFS_COMPRESSION_XZ should take care of it
	find . -print0 | cpio --null --create --verbose --format=newc >> "${S}"/build/bootengine.cpio
	popd || die
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

	insinto "/usr/lib/flatcar"
	doins build/bootengine.img
}
