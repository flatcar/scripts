#!/bin/bash

# Copyright (c) 2014 The CoreOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Replacement script for 'grub-install' which does not detect drives
# properly when partitions are mounted via individual loopback devices.

SCRIPT_ROOT=$(readlink -f $(dirname "$0")/..)
. "${SCRIPT_ROOT}/common.sh" || exit 1

# We're invoked only by build_image, which runs in the chroot
assert_inside_chroot

# Flags.
DEFINE_string board "${DEFAULT_BOARD}" \
  "The name of the board"
DEFINE_string target "" \
  "The GRUB target to install such as i386-pc or x86_64-efi"
DEFINE_string disk_image "" \
  "The disk image containing the EFI System partition."
DEFINE_boolean verity ${FLAGS_FALSE} \
  "Indicates that boot commands should enable dm-verity."
DEFINE_string copy_efi_grub "" \
  "Copy the EFI GRUB image to the specified path."
DEFINE_string copy_shim "" \
  "Copy the shim image to the specified path."

# Parse flags
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"
switch_to_strict_mode

# must be sourced after flags are parsed.
. "${BUILD_LIBRARY_DIR}/toolchain_util.sh" || exit 1
. "${BUILD_LIBRARY_DIR}/board_options.sh" || exit 1
. "${BUILD_LIBRARY_DIR}/sbsign_util.sh" || exit 1

# Our GRUB lives under flatcar/grub so new pygrub versions cannot find grub.cfg
GRUB_DIR="flatcar/grub/${FLAGS_target}"

# Modules required to boot a standard CoreOS configuration
CORE_MODULES=( normal search test fat part_gpt search_fs_uuid xzio search_part_label terminal gptprio configfile memdisk tar echo read btrfs )

SBAT_ARG=()

case "${FLAGS_target}" in
    x86_64-efi)
        EFI_ARCH="x64"
        ;;
    arm64-efi)
        EFI_ARCH="aa64"
        ;;
esac

case "${FLAGS_target}" in
    x86_64-efi|arm64-efi)
        GRUB_IMAGE="EFI/boot/grub${EFI_ARCH}.efi"
        CORE_MODULES+=( serial linux efi_gop efinet pgp http tftp tpm )
        SBAT_ARG=( --sbat "${BOARD_ROOT}/usr/share/grub/sbat.csv" )
        ;;
    i386-pc)
        GRUB_IMAGE="${GRUB_DIR}/core.img"
        CORE_MODULES+=( biosdisk serial )
        ;;
    x86_64-xen)
        GRUB_IMAGE="xen/pvboot-x86_64.elf"
        ;;
    *)
        die_notrace "Unknown GRUB target ${FLAGS_target}"
        ;;
esac

info "Updating GRUB in ${BOARD_ROOT}"
emerge-${BOARD} \
        --nodeps --select --verbose --update --getbinpkg --usepkgonly --newuse \
        sys-boot/grub

GRUB_SRC="${BOARD_ROOT}/usr/lib/grub/${FLAGS_target}"
[[ -d "${GRUB_SRC}" ]] || die "GRUB not installed at ${GRUB_SRC}"

# In order for grub-setup-bios to properly detect the layout of the disk
# image it expects a normal partitioned block device. For most of the build
# disk_util maps individual loop devices to each partition in the image so
# the kernel can automatically detach the loop devices on unmount. When
# using a single loop device with partitions there is no such cleanup.
# That's the story of why this script has all this goo for loop and mount.
ESP_DIR=
LOOP_DEV=

cleanup() {
    cleanup_sbsign_certs
    if [[ -d "${ESP_DIR}" ]]; then
        if mountpoint -q "${ESP_DIR}"; then
            sudo umount "${ESP_DIR}"
        fi
        rm -rf "${ESP_DIR}"
    fi
    if [[ -b "${LOOP_DEV}" ]]; then
        sudo losetup --detach "${LOOP_DEV}"
    fi
    if [[ -n "${GRUB_TEMP_DIR}" && -e "${GRUB_TEMP_DIR}" ]]; then
      rm -r "${GRUB_TEMP_DIR}"
    fi
}
trap cleanup EXIT

info "Installing GRUB ${FLAGS_target} in ${FLAGS_disk_image##*/}"
LOOP_DEV=$(sudo losetup --find --show --partscan "${FLAGS_disk_image}")
ESP_DIR=$(mktemp --directory)
MOUNTED=

for (( i=0; i<5; ++i )); do
    if sudo mount -t vfat "${LOOP_DEV}p1" "${ESP_DIR}"; then
        MOUNTED=x
        break
    fi
    warn "loopback device node ${LOOP_DEV}p1 still missing, reprobing..."
    sudo blockdev --rereadpt "${LOOP_DEV}"
    # sleep for 0.5, then 1, then 2, then 4, then 8 seconds.
    sleep "$(bc <<<"scale=1; (2.0 ^ ${i}) / 2.0")"
done
if [[ -z ${MOUNTED} ]]; then
    failboat "${LOOP_DEV}p1 where art thou? udev has forsaken us!"
fi
sudo mkdir -p "${ESP_DIR}/${GRUB_DIR}" "${ESP_DIR}/${GRUB_IMAGE%/*}"

# Additional GRUB modules cannot be loaded with Secure Boot enabled, so only
# copy and compress these for target that don't support it.
case "${FLAGS_target}" in
    x86_64-efi|arm64-efi) : ;;
    *)
        info "Compressing modules in ${GRUB_DIR}"
        for file in "${GRUB_SRC}"/*{.lst,.mod}; do
            for core_mod in "${CORE_MODULES[@]}"; do
                [[ ${file} == ${GRUB_SRC}/${core_mod}.mod ]] && continue 2
            done
            out="${ESP_DIR}/${GRUB_DIR}/${file##*/}"
            xz --stdout "${file}" | sudo_clobber "${out}"
        done
        ;;
esac

info "Generating ${GRUB_DIR}/load.cfg"
# Include a small initial config in the core image to search for the ESP
# by filesystem ID in case the platform doesn't provide the boot disk.
# $root points to memdisk here so instead use hd0,gpt1 as a hint so it is
# searched first.
ESP_FSID=$(sudo grub-probe -t fs_uuid -d "${LOOP_DEV}p1")
sudo_clobber "${ESP_DIR}/${GRUB_DIR}/load.cfg" <<EOF
search.fs_uuid ${ESP_FSID} root hd0,gpt1
set prefix=(memdisk)
set
EOF

# Generate a memdisk containing the appropriately generated grub.cfg. Doing
# this because we need conflicting default behaviors between verity and
# non-verity images.
GRUB_TEMP_DIR=$(mktemp -d)
if [[ ! -f "${ESP_DIR}/flatcar/grub/grub.cfg.tar" ]]; then
    info "Generating grub.cfg memdisk"

    if [[ ${FLAGS_verity} -eq ${FLAGS_TRUE} ]]; then
      # use dm-verity for /usr
      cat "${BUILD_LIBRARY_DIR}/grub.cfg" | \
        sed 's/@@MOUNTUSR@@/mount.usr=\/dev\/mapper\/usr verity.usr/' > \
        "${GRUB_TEMP_DIR}/grub.cfg"
    else
      # uses standard systemd /usr mount
      cat "${BUILD_LIBRARY_DIR}/grub.cfg" | \
        sed 's/@@MOUNTUSR@@/mount.usr/' > "${GRUB_TEMP_DIR}/grub.cfg"
    fi

    sudo tar cf "${ESP_DIR}/flatcar/grub/grub.cfg.tar" \
      -C "${GRUB_TEMP_DIR}" "grub.cfg"
fi

info "Generating ${GRUB_IMAGE}"
sudo grub-mkimage \
    --compression=xz \
    --format "${FLAGS_target}" \
    --directory "${GRUB_SRC}" \
    --config "${ESP_DIR}/${GRUB_DIR}/load.cfg" \
    --memdisk "${ESP_DIR}/flatcar/grub/grub.cfg.tar" \
    "${SBAT_ARG[@]}" \
    --output "${ESP_DIR}/${GRUB_IMAGE}" \
    "${CORE_MODULES[@]}"

# Now target specific steps to make the system bootable
case "${FLAGS_target}" in
    x86_64-efi|arm64-efi)
        info "Installing default ${FLAGS_target} UEFI bootloader."

        if [[ ${COREOS_OFFICIAL:-0} -ne 1 ]]; then
            # Sign GRUB and mokmanager(mm) with the shim-embedded key.
            do_sbsign --output "${ESP_DIR}/${GRUB_IMAGE}"{,}
            do_sbsign --output "${ESP_DIR}/EFI/boot/mm${EFI_ARCH}.efi" \
                "${BOARD_ROOT}/usr/lib/shim/mm${EFI_ARCH}.efi"

            # Unofficial build: Sign shim with our development key.
            sudo sbsign \
                --key /usr/share/sb_keys/DB.key \
                --cert /usr/share/sb_keys/DB.crt \
                --output "${ESP_DIR}/EFI/boot/boot${EFI_ARCH}.efi" \
                "${BOARD_ROOT}/usr/lib/shim/shim${EFI_ARCH}.efi"
        else
            # Official build: Copy signed shim and mm for signing later.
            sudo cp "${BOARD_ROOT}/usr/lib/shim/mm${EFI_ARCH}.efi" \
                "${ESP_DIR}/EFI/boot/mm${EFI_ARCH}.efi"
            sudo cp "${BOARD_ROOT}/usr/lib/shim/shim${EFI_ARCH}.efi.signed" \
                "${ESP_DIR}/EFI/boot/boot${EFI_ARCH}.efi"
        fi

        # copying from vfat so ignore permissions
        if [[ -n ${FLAGS_copy_efi_grub} ]]; then
            cp --no-preserve=mode "${ESP_DIR}/${GRUB_IMAGE}" \
                "${FLAGS_copy_efi_grub}"
        fi
        if [[ -n ${FLAGS_copy_shim} ]]; then
            cp --no-preserve=mode "${ESP_DIR}/EFI/boot/boot${EFI_ARCH}.efi" \
                "${FLAGS_copy_shim}"
        fi
        ;;
    i386-pc)
        info "Installing MBR and the BIOS Boot partition."
        sudo cp "${GRUB_SRC}/boot.img" "${ESP_DIR}/${GRUB_DIR}"
        sudo grub-bios-setup --device-map=/dev/null \
            --directory="${ESP_DIR}/${GRUB_DIR}" "${LOOP_DEV}"
        # boot.img gets manipulated by grub-bios-setup so it alone isn't
        # sufficient to restore the MBR boot code if it gets corrupted.
        sudo dd bs=448 count=1 status=none if="${LOOP_DEV}" \
            of="${ESP_DIR}/${GRUB_DIR}/mbr.bin"
        ;;
    x86_64-xen)
        info "Installing default x86_64 Xen bootloader."
        sudo mkdir -p "${ESP_DIR}/boot/grub"
        sudo cp "${BUILD_LIBRARY_DIR}/menu.lst" \
            "${ESP_DIR}/boot/grub/menu.lst"
        ;;
esac

cleanup
trap - EXIT
command_completed
