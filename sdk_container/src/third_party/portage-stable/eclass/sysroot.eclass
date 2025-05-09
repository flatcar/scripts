# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: sysroot.eclass
# @MAINTAINER:
# cross@gentoo.org
# @AUTHOR:
# James Le Cuirot <chewi@gentoo.org>
# @SUPPORTED_EAPIS: 7 8
# @BLURB: Common functions for using a different sysroot (e.g. cross-compiling)

case ${EAPI} in
	7|8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

# @FUNCTION: qemu_arch
# @DESCRIPTION:
# Return the QEMU architecture name for the given target or CHOST. This name is
# used in qemu-user binary filenames, e.g. qemu-ppc64le.
qemu_arch() {
	local target=${1:-${CHOST}}
	case ${target} in
		armeb*) echo armeb ;;
		arm*) echo arm ;;
		hppa*) echo hppa ;;
		i?86*) echo i386 ;;
		mips64el*-gnuabi64) echo mips64el ;;
		mips64el*-gnuabin32) echo mipsn32el ;;
		mips64*-gnuabi64) echo mips64 ;;
		mips64*-gnuabin32) echo mipsn32 ;;
		powerpc64le*) echo ppc64le ;;
		powerpc64*) echo ppc64 ;;
		powerpc*) echo ppc ;;
		*) echo "${target%%-*}" ;;
	esac
}

# @FUNCTION: sysroot_make_run_prefixed
# @DESCRIPTION:
# Create a wrapper script for directly running executables within a sysroot
# without changing the root directory. The path to that script is returned. If
# no sysroot has been set, then this function returns unsuccessfully.
#
# The script explicitly uses QEMU if this is necessary and it is available in
# this environment. It may otherwise implicitly use a QEMU outside this
# environment if binfmt_misc has been used with the F flag. It is not feasible
# to add a conditional dependency on QEMU.
sysroot_make_run_prefixed() {
	[[ -z ${SYSROOT} ]] && return 1

	local SCRIPT="${T}"/sysroot-run-prefixed
	local QEMU_ARCH=$(qemu_arch)

	if [[ ${QEMU_ARCH} == $(qemu_arch "${CBUILD}") ]]; then
		# glibc: ld.so is a symlink, ldd is a binary.
		# musl: ld.so doesn't exist, ldd is a symlink.
		local DYNLINKER=$(find "${ESYSROOT}"/usr/bin/{ld.so,ldd} -type l -print -quit 2>/dev/null || die "failed to find dynamic linker")

		# musl symlinks ldd to ld-musl.so to libc.so. We want the ld-musl.so
		# path, not the libc.so path, so don't resolve the symlinks entirely.
		DYNLINKER=$(readlink -ev "${DYNLINKER}" || die "failed to find dynamic linker")

		# Using LD_LIBRARY_PATH to set the prefix is not perfect, as it doesn't
		# adjust RUNPATHs, but it is probably good enough.
		install -m0755 /dev/stdin "${SCRIPT}" <<-EOF || die
			#!/bin/sh
			LD_LIBRARY_PATH="\${LD_LIBRARY_PATH}\${LD_LIBRARY_PATH+:}${ESYSROOT}/$(get_libdir):${ESYSROOT}/usr/$(get_libdir)" exec "${DYNLINKER}" "\${@}"
		EOF
	else
		# QEMU_LD_PREFIX rather than QEMU's -L argument is used to set the
		# prefix to cover both explicit and implicit QEMU usage.
		install -m0755 /dev/stdin "${SCRIPT}" <<-EOF || die
			#!/bin/sh
			QEMU_LD_PREFIX="${SYSROOT}" exec $(type -P "qemu-${QEMU_ARCH}") "\${@}"
		EOF
	fi

	echo "${SCRIPT}"
}
