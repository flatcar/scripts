# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit coreos-kernel

BASE_P=linux-${PV%.*}
PATCH_PV=${PV%_p*}

DESCRIPTION="Minimalist opinionated Linux kernel for VM workloads"
HOMEPAGE="
  https://www.kernel.org/
"
KEYWORDS="amd64 arm64"

SRC_URI="${KERNEL_URI}"
PATCH_DIR="${FILESDIR}/${KV_MAJOR}.${KV_MINOR}"

src_prepare() {
  default
  local config=""
  case "${PN}" in
    *-debug) config="${FILESDIR}/microvm-debug.kconfig";;
    *) config="${FILESDIR}/microvm.kconfig";;
  esac

  elog "Building using config ${config}"
  cp "${config}" build/.config || die
}
# --

src_compile() {
  # Cloud hypervisor can't use compressed kernels
	kmake vmlinux
}
# --

# TODO: adjust to microvm build needs
src_install() {
  local suffix=""
  case "${PN}" in
    *-debug) suffix="-debug"
  esac

	insinto "/usr/boot"
	newins build/vmlinux "vmlinux-microvm${suffix}"
	newins build/.config "vmlinux-microvm${suffix}.kconfig"
}
# --
