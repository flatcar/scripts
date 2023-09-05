# Copyright 2014 CoreOS, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
ETYPE="sources"

# -rc releases should be versioned L.M_rcN
# Final releases should be versioned L.M.N, even for N == 0

# Only needed for RCs
K_BASE_VER="5.15"

inherit kernel-2
EXTRAVERSION="-flatcar"
detect_version

DESCRIPTION="Full sources for the CoreOS Linux kernel"
HOMEPAGE="http://www.kernel.org"
if [[ "${PV%%_rc*}" != "${PV}" ]]; then
	SRC_URI="https://git.kernel.org/torvalds/p/v${KV%-coreos}/v${OKV} -> patch-${KV%-coreos}.patch ${KERNEL_BASE_URI}/linux-${OKV}.tar.xz"
	PATCH_DIR="${FILESDIR}/${KV_MAJOR}.${KV_PATCH}"
else
	SRC_URI="${KERNEL_URI}"
	PATCH_DIR="${FILESDIR}/${KV_MAJOR}.${KV_MINOR}"
fi

# make modules_prepare depends on pahole
RDEPEND="dev-util/pahole"

KEYWORDS="amd64 arm64"
IUSE=""

# XXX: Note we must prefix the patch filenames with "z" to ensure they are
# applied _after_ a potential patch-${KV}.patch file, present when building a
# patchlevel revision.  We mustn't apply our patches first, it fails when the
# local patches overlap with the upstream patch.
UNIPATCH_LIST="
	${PATCH_DIR}/z0001-kbuild-derive-relative-path-for-srctree-from-CURDIR.patch \
	${PATCH_DIR}/z0002-tools-objtool-Makefile-Don-t-fail-on-fallthrough-wit.patch \
	${PATCH_DIR}/z0003-PCI-hv-Make-the-code-arch-neutral-by-adding-arch-spe.patch \
	${PATCH_DIR}/z0004-PCI-hv-Add-arm64-Hyper-V-vPCI-support.patch \
	${PATCH_DIR}/z0005-Drivers-hv-vmbus-Propagate-VMbus-coherence-to-each-V.patch \
	${PATCH_DIR}/z0006-PCI-hv-Avoid-the-retarget-interrupt-hypercall-in-irq.patch \
	${PATCH_DIR}/z0007-PCI-hv-Remove-unused-hv_set_msi_entry_from_desc.patch \
	${PATCH_DIR}/z0008-net-mlx5-Free-IRQ-rmap-and-notifier-on-kernel-shutdo.patch \
"
