#!/usr/bin/env bash
# Convert the disk ($1) to FLATCAR_VM_TYPE's format with image_to_vm.sh's
# write_vm_*; the layout and OEM partition are already done by mkosi.
set -euo pipefail

[[ "${MKOSI_DEBUG:-0}" == "1" ]] && set -x

# Post-output scripts get no ARTIFACTDIR; lib.sh needs it only for BUILD_DIR.
export ARTIFACTDIR="${ARTIFACTDIR:-$(mktemp -d)}"
. "${SRCDIR}/lib/lib.sh"

img="${1:?usage: write-vm-image.sh DISK_IMAGE}"
outdir="$(dirname "${img}")"

set_vm_type "${FLATCAR_VM_TYPE:?FLATCAR_VM_TYPE must be set}" \
  || die "Unknown FLATCAR_VM_TYPE=${FLATCAR_VM_TYPE}"

# As set_vm_paths; the source name only derives the vendor file names.
src_name=flatcar_production_image.bin
VM_SRC_IMG="${outdir}/${src_name}"
VM_DST_IMG="${outdir}/$(_src_to_dst_name "${src_name}" "_image.$(_disk_ext)")"
VM_TMP_DIR="$(mktemp -d)"
trap 'umount -q "${VM_TMP_ROOT}" || :; rm -rf "${VM_TMP_DIR}"' EXIT
VM_TMP_IMG="${VM_TMP_DIR}/disk_image.bin"
VM_TMP_ROOT="${VM_TMP_DIR}/rootfs"
VM_NAME="$(_src_to_dst_name "${src_name}" "")-${FLATCAR_VERSION}"
VM_NAME="${VM_NAME//./-}"
VM_NAME="${VM_NAME//+/-}"
VM_README="${outdir}/$(_src_to_dst_name "${src_name}" ".README")"
VM_GENERATED_FILES=()

cp --reflink=auto --sparse=always "${img}" "${VM_TMP_IMG}"
# write_vm_disk unmounts VM_TMP_ROOT, which image_to_vm.sh would have mounted.
mkdir -p "${VM_TMP_ROOT}"
mount -t tmpfs vm-tmp-root "${VM_TMP_ROOT}"
write_vm_disk
write_vm_conf
write_vm_bundle

printf '[vm-image] wrote %s\n' "${VM_GENERATED_FILES[@]##*/}"
