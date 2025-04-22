#!/bin/bash

# Does as it says on the tin.
#
# Example: extract-initramfs-from-vmlinuz /boot/flatcar/vmlinuz-a out-dir
#
# This will create one or more out-dir/rootfs-N directories that contain the contents of the initramfs.

set -euo pipefail

# check for xzcat. Will abort the script with an error message if the tool is not present.
xzcat -V >/dev/null

fail() {
    echo "${*}" >&2
    exit 1
}

find_xz_headers() {
    grep --fixed-strings --text --byte-offset --only-matching $'\xFD\x37\x7A\x58\x5A\x00' "$1" | cut -d: -f1
}

decompress_at() {
    # Data may not really be a valid xz, so allow for errors.
    tail "-c+$((${2%:*} + 1))" "$1" | xzcat 2>/dev/null || true
}

try_extract() {
    # cpio can do strange things when given garbage, so do a basic check.
    [[ $(head -c6 "$1") == 070701 ]] || return 0

    # There may be multiple concatenated archives so try cpio till it fails.
    while cpio --quiet --extract --make-directories --directory="${out}/rootfs-${ROOTFS_IDX}" --nonmatching 'dev/*' 2>/dev/null; do
        ROOTFS_IDX=$(( ROOTFS_IDX + 1 ))
    done < "$1"

    # Last cpio attempt may or may not leave an empty directory.
    rmdir "${out}/rootfs-${ROOTFS_IDX}" 2>/dev/null || ROOTFS_IDX=$(( ROOTFS_IDX + 1 ))
}

me="${0##*/}"
if [[ $# -ne 2 ]]; then
    fail "Usage: ${me} <vmlinuz> <output_directory>"
fi
image="${1}"
out="${2}"
if [[ ! -s "${image}" ]]; then
    fail "The image file '${image}' either does not exist or is empty"
fi
mkdir -p "${out}"

tmp=$(mktemp --directory eifv-XXXXXX)
trap 'rm -rf -- "${tmp}"' EXIT
ROOTFS_IDX=0

# arm64 kernels are not compressed, so try decompressing once.
# Other kernels are compressed, so also try decompressing twice.
for OFF1 in $(find_xz_headers "${image}")
do
    decompress_at "${image}" "${OFF1}" > "${tmp}/initrd.maybe_cpio_or_elf"
    try_extract "${tmp}/initrd.maybe_cpio_or_elf"

    for OFF2 in $(find_xz_headers "${tmp}/initrd.maybe_cpio_or_elf")
    do
        decompress_at "${tmp}/initrd.maybe_cpio_or_elf" "${OFF2}" > "${tmp}/initrd.maybe_cpio"
        try_extract "${tmp}/initrd.maybe_cpio"
    done
done

if [[ ${ROOTFS_IDX} -eq 0 ]]; then
    fail "no initramfs found in ${image}"
fi

echo "done, found ${ROOTFS_IDX} rootfs(es)"
