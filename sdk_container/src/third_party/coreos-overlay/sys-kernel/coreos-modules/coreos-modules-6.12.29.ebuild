# Copyright 2014-2016 CoreOS, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
COREOS_SOURCE_REVISION=""
inherit coreos-kernel savedconfig

DESCRIPTION="CoreOS Linux kernel modules"
KEYWORDS="amd64 arm64"
RDEPEND="!<sys-kernel/coreos-kernel-4.6.3-r1"

src_prepare() {
	default
	restore_config build/.config
	if [[ ! -f build/.config ]]; then
		local archconfig="$(find_archconfig)"
		local commonconfig="$(find_commonconfig)"
		elog "Building using config ${archconfig} and ${commonconfig}"
		cat "${archconfig}" "${commonconfig}" | envsubst '$MODULE_SIGNING_KEY_DIR' >> build/.config || die
	fi
	cpio -ov </dev/null >build/bootengine.cpio

	# Check that an old pre-ebuild-split config didn't leak in.
	grep -q "^CONFIG_INITRAMFS_SOURCE=" build/.config && \
		die "CONFIG_INITRAMFS_SOURCE must be removed from kernel config"
	config_update 'CONFIG_INITRAMFS_SOURCE="bootengine.cpio"'
}

src_compile() {
	# Generate module signing key
	setup_keys

	# Build both vmlinux and modules (moddep checks symbols in vmlinux)
	kmake vmlinux modules
}

src_install() {
	local build="lib/modules/${KV_FULL}/build"

	# Install modules to /usr.
	# Stripping must be done here, not portage, to preserve sigs.
	kmake INSTALL_MOD_PATH="${ED}/usr" \
		  INSTALL_MOD_STRIP="--strip-debug" \
		  modules_install

	# Install to /usr/lib/debug with debug symbols intact
	kmake INSTALL_MOD_PATH="${ED}/usr/lib/debug/usr" \
		  modules_install
	rm "${ED}/usr/lib/debug/usr/lib/modules/${KV_FULL}"/{build,modules.*} || die

	# Replace the broken /lib/modules/${KV_FULL}/build symlink with a copy of
	# the files needed to build out-of-tree modules.
	rm "${ED}/usr/${build}" || die
	kmake run-command KBUILD_RUN_COMMAND="${KERNEL_DIR}/scripts/package/install-extmod-build ${ED}/usr/${build}"

	# Install the original config because the above doesn't.
	insinto "/usr/${build}"
	doins build/.config

	# Not strictly required but this is where we used to install the config.
	dosym "../${build}/.config" "/usr/boot/config-${KV_FULL}"
	dosym "../${build}/.config" "/usr/boot/config"
}
