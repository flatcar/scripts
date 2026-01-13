# Copyright 2014-2016 CoreOS, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI=8
COREOS_SOURCE_REVISION=""
inherit coreos-kernel toolchain-funcs

DESCRIPTION="CoreOS Linux kernel"
KEYWORDS="amd64 arm64"
RESTRICT="userpriv" # dracut (via bootengine) needs root

RDEPEND="
	=sys-kernel/coreos-modules-${PVR}
	sys-apps/kbd
"
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
	net-misc/iputils
	sys-apps/azure-vm-utils[dracut]
	sys-apps/baselayout
	sys-apps/busybox
	sys-apps/coreutils
	sys-apps/findutils
	sys-apps/grep
	sys-apps/hwdata
	sys-apps/ignition:=
	sys-apps/iproute2
	sys-apps/kexec-tools
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
	sys-process/procps
	virtual/udev
	amd64? (
		app-admin/google-guest-configs[-flatcar-oem]
		sys-firmware/intel-microcode:=
	)
"

src_prepare() {
	default

	# KV_OUT_DIR points to the minimal build tree installed by coreos-modules
	# Pull in the config and public module signing key
	cp -v "${KV_OUT_DIR}/.config" build/ || die
	validate_sig_key

	config_update 'CONFIG_INITRAMFS_SOURCE="bootengine.cpio"'

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
	# Copy full initrd over to /usr as filesystem image
	mkdir "${S}"/build/bootengine || die
	pushd "${S}"/build/bootengine || die
	lsinitrd --kver SILENCEERROR --unpack "${S}"/build/bootengine.cpio || die
	mksquashfs . "${S}"/build/bootengine.img -noappend -xattrs-exclude ^btrfs. || die
	popd || die
	# No early cpio, drop full initrd
	> "${S}"/build/bootengine.cpio
	# Create minimal initrd
	mkdir "${S}"/build/minimal || die
	pushd "${S}"/build/minimal || die
	mkdir -p {etc,dev,proc,sys,dev,usr/bin,usr/lib,usr/lib64,realinit,sysusr/usr} || die
	ln -s usr/bin bin || die
	ln -s usr/bin sbin || die
	ln -s bin usr/sbin || die
	ln -s usr/lib lib || die
	ln -s usr/lib64 lib64 || die
	# Instead from ESYSROOT we can also copy kernel modules from the dracut pre-selection
	mkdir -p lib/modprobe.d/ || die
	cp "${S}"/build/bootengine/lib/modprobe.d/* lib/modprobe.d/ || die
	# Only include modules related to mounting /usr and for interacting with the emergency console
	pushd "${S}/build/bootengine/usr/lib/modules/${KV_FULL}" || die
	find kernel/drivers/{ata,block,hid,hv,input/serio,message/fusion,mmc,nvme,pci,scsi,usb} kernel/fs/{btrfs,overlayfs,squashfs} kernel/security/keys -name "*.ko.*" -printf "%f\0" | DRACUT_NO_XATTR=1 xargs --null "${BROOT}"/usr/lib/dracut/dracut-install --destrootdir "${S}"/build/minimal --kerneldir . --sysrootdir "${S}"/build/bootengine/ --firmwaredirs "${S}"/build/bootengine/usr/lib/firmware --module dm-verity dm-mod virtio_console || die
	popd || die
	# Double compression only makes the image bigger and slower
	find . -name "*.ko.xz" -exec unxz {} + || die
	depmod -a -b . "${KV_FULL}" || die
	echo '$MODALIAS=.*	0:0 660 @/sbin/modprobe "$MODALIAS"' > ./etc/mdev.conf || die
	# We can't use busybox's modprobe because it doesn't support the globs in module.alias, breaking module loading
	DRACUT_NO_XATTR=1 "${BROOT}"/usr/lib/dracut/dracut-install --destrootdir . --sysrootdir "${ESYSROOT}" --ldd /bin/veritysetup /bin/dmsetup /bin/busybox /sbin/modprobe || die
	cp -a "${ESYSROOT}"/usr/bin/minimal-init ./init || die
	# Make it easier to debug by not relying too much on the first commands
	ln -s busybox ./bin/sh || die
	mknod ./dev/console c 5 1 || die
	mknod ./dev/null c 1 3 || die
	mknod ./dev/tty c 5 0 || die
	mknod ./dev/urandom c 1 9 || die
	mknod ./dev/random c 1 8 || die
	mknod ./dev/zero c 1 5 || die
	# No compression because CONFIG_INITRAMFS_COMPRESSION_XZ should take care of it
	# (Note: The kernel build system does not support prepending an uncompressed microcode early cpio here)
	find . -print0 | cpio --null --create --verbose --format=newc >> "${S}"/build/bootengine.cpio || die
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
