#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

SCRIPT_ROOT=$(readlink -f $(dirname "$0")/../..)
. "${SCRIPT_ROOT}/common.sh" || exit 1

# We're invoked only by build_image, which runs in the chroot
assert_inside_chroot

DEFINE_string board "${DEFAULT_BOARD}" \
  "The name of the board"
DEFINE_string target "" \
  "The UEFI target: x86_64-efi or arm64-efi"
DEFINE_string disk_image "" \
  "The disk image containing the EFI System partition."
DEFINE_boolean verity ${FLAGS_FALSE} \
  "Indicates that boot commands should enable dm-verity."
DEFINE_string verity_hash "" \
  "Path to the file containing the dm-verity root hash for /usr."

# Parse flags
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"
switch_to_strict_mode

# Must be sourced after flags are parsed
. "${BUILD_LIBRARY_DIR}/toolchain_util.sh" || exit 1
. "${BUILD_LIBRARY_DIR}/board_options.sh"  || exit 1

# Determine EFI architecture suffix
case "${FLAGS_target}" in
    x86_64-efi)
        EFI_ARCH="x64"
        RPM_ARCH="x86_64"
        ;;
    arm64-efi)
        EFI_ARCH="aa64"
        RPM_ARCH="aarch64"
        ;;
    i386-pc|x86_64-xen)
        # UKI is UEFI-only — nothing to do for legacy targets
        info "UKI: Target ${FLAGS_target} is not UEFI; skipping."
        exit 0
        ;;
    *)
        die_notrace "Unknown target ${FLAGS_target}"
        ;;
esac

uki_install_rpm() {
    info "UKI/RPM mode: Installing systemd-boot and shim to BOARD_ROOT"

    # Verify that ukify is available in the SDK
    if ! command -v ukify &>/dev/null; then
        die "UKI/RPM: ukify not found in SDK. Ensure the SDK container was built with systemd[boot,ukify]."
    fi
    info "UKI/RPM: Using SDK-provided ukify from $(command -v ukify)"

    # Source rpm_install functions for rpm_get_staging_dir
    . "${BUILD_LIBRARY_DIR}/rpm/rpm_install.sh" || die "Failed to source rpm_install.sh"

    # Locate the RPM cache directory
    rpm_staging=$(rpm_get_staging_dir)
    local uki_local_cache="${RPM_LOCAL_CACHE:-${rpm_staging}}"

    # Note: systemd-boot and shim packages should already be downloaded by finish_image_rpm()
    # No need to call rpm_download_packages again - the packages are in the local cache

    # Find systemd-boot and shim RPMs in local cache — filter by target architecture
    local uki_rpms=()
    local rpm_file
    for pkg in systemd-boot shim; do
        rpm_file=$(find "${uki_local_cache}" -name "${pkg}-[0-9]*.${RPM_ARCH}.rpm" | sort -V | tail -1)
        if [[ -z "${rpm_file}" ]]; then
            die "RPM file not found for package: ${pkg} (${RPM_ARCH}) in ${uki_local_cache}"
        fi
        uki_rpms+=("${rpm_file}")
    done

    # Import GPG key and install packages
    rpm_import_gpg_key "${BOARD_ROOT}"
    rpm_install_local_packages "${BOARD_ROOT}" "${uki_rpms[@]}" || die "Failed to install systemd-boot and shim to BOARD_ROOT"
}

uki_provision_rpm() {
    local ESP_DIR="$1"

    info "UKI/RPM: Provisioning systemd-boot + UKI on ESP"

    # The kernel is at /boot/vmlinuz-* (placed by the kernel RPM) and the
    # initrd is at /boot/flatcar/initramfs-a.img (placed by finish_image_rpm).
    # In grub mode the kernel gets moved to /boot/flatcar/vmlinuz-a, but in
    # UKI mode it stays at its original RPM-installed path.
    local kernel=""
    local -a _kernels=("${ESP_DIR}"/vmlinuz-*)
    for _k in "${_kernels[@]}"; do
        [[ -f "$_k" && "$_k" != *.hmac ]] && kernel="$_k" && break
    done
    if [[ -z "${kernel}" ]]; then
        # Fallback: check legacy path for grub-mode compat
        kernel="${ESP_DIR}/flatcar/vmlinuz-a"
    fi
    if [[ ! -f "${kernel}" ]]; then
        die "UKI/RPM: Kernel not found on ESP (tried ${ESP_DIR}/vmlinuz-* and ${ESP_DIR}/flatcar/vmlinuz-a)"
    fi

    local initrd="${ESP_DIR}/flatcar/initramfs-a.img"
    if [[ ! -f "${initrd}" ]]; then
        die "UKI/RPM: Initrd not found at ${initrd}"
    fi

    # Temp directory for all intermediate files.
    local uki_temp_dir
    uki_temp_dir=$(mktemp -d)

    # Generate os-release for the UKI.
    local osrelease="${uki_temp_dir}/os-release"
    cat > "${osrelease}" <<-OSREL
		NAME="Microsoft Azure Container Linux"
		ID=azurelinux
		ID_LIKE="flatcar"
        VARIANT="Azure Container Linux"
        VARIANT_ID="azurecontainerlinux"
		VERSION="${IMAGE_VERSION:-0.0.0}"
		VERSION_ID="${IMAGE_VERSION_ID:-0.0.0}"
		PRETTY_NAME="Microsoft Azure Container Linux ${IMAGE_VERSION:-}"
OSREL
    info "UKI/RPM: Generated os-release for UKI"

    if ! command -v ukify &>/dev/null; then
        die "UKI/RPM: ukify not found on PATH; uki_install_rpm() should have installed it"
    fi
    info "UKI/RPM: Using ukify from $(command -v ukify)"

    # Read partition UUID and compute verity hash offset from the
    # canonical UKI disk layout so the values never drift from the source.
    local disk_layout_file="${BUILD_LIBRARY_DIR}/disk_layout_uki.json"
    if [[ ! -f "${disk_layout_file}" ]]; then
        die "UKI/RPM: disk_layout_uki.json not found at ${disk_layout_file}"
    fi

    local usr_a_uuid
    usr_a_uuid=$(jq -r '.layouts.base["2"].uuid' "${disk_layout_file}")

    local verity_hash_offset
    verity_hash_offset=$(jq -r \
        '(.layouts.base["2"].fs_blocks | tonumber) as $b | (.metadata.fs_block_size | tonumber) as $s | ($b * $s)' \
        "${disk_layout_file}")

    info "UKI/RPM: USR-A uuid=${usr_a_uuid}  verity hash-offset=${verity_hash_offset}"

    local cmdline=""
    if [[ ${FLAGS_verity} -eq ${FLAGS_TRUE} ]]; then
        local usr_hash=""
        if [[ -n "${FLAGS_verity_hash}" && -f "${FLAGS_verity_hash}" ]]; then
            usr_hash=$(cat "${FLAGS_verity_hash}")
            info "UKI/RPM: Verity hash = ${usr_hash}"
        else
            die "UKI/RPM: Verity enabled but no hash file at ${FLAGS_verity_hash}"
        fi
        cmdline="mount.usr=/dev/mapper/usr mount.usrflags=ro"
        cmdline+=" systemd.verity_usr_data=PARTUUID=${usr_a_uuid}"
        cmdline+=" systemd.verity_usr_hash=PARTUUID=${usr_a_uuid}"
        cmdline+=" systemd.verity_usr_options=hash-offset=${verity_hash_offset},panic-on-corruption"
        cmdline+=" usrhash=${usr_hash}"
    else
        cmdline="mount.usr=PARTUUID=${usr_a_uuid} mount.usrflags=ro"
    fi
    # Common base args — platform-agnostic, same for all image types.
    cmdline+=" root=LABEL=ROOT rootflags=rw"
    cmdline+=" consoleblank=0"
    # NOTE: crashkernel=256M is delivered via a UKI addon (kdump.addon.efi)
    # rather than baked into the main UKI cmdline.  This allows disabling
    # kdump by removing the addon from the ESP without rebuilding the UKI.
    # See _uki_build_kdump_addon() below.
    # OEM / platform identification (oem_id, ignition platform, console
    # settings, etc.) are NOT baked into the main UKI.  They are injected
    # via a per-platform UKI addon built during image_to_vm.sh so that
    # each VM image format gets the correct OEM-specific cmdline.
    # See build_library/rpm/uki_addon.sh for the addon builder.
    #
    # NOTE: first-boot args (flatcar.first_boot=detected) are deliberately
    # NOT baked into the main UKI cmdline because they must only appear on
    # the very first boot.  Instead, a separate firstboot addon EFI is
    # placed in the .extra.d/ directory; ignition-quench.service deletes it
    # after Ignition completes, mirroring how GRUB uses the
    # /boot/flatcar/first_boot marker file.
    # See _uki_build_firstboot_addon() below.

    # Write cmdline to a temp file for ukify
    echo "${cmdline}" > "${uki_temp_dir}/cmdline.txt"
    info "UKI/RPM: cmdline = ${cmdline}"

    # Determine kernel version for UAPI UKI naming (vmlinuz-<version>.efi).
    local kernel_version
    local -a kfiles=()
    local kf
    for kf in "${ESP_DIR}"/vmlinuz-* "${ESP_DIR}"/boot/vmlinuz-*; do
        [[ -f "${kf}" ]] && kfiles+=("${kf}")
    done
    if [[ ${#kfiles[@]} -eq 0 ]]; then
        die "UKI/RPM: No versioned vmlinuz-* found on ESP (${ESP_DIR})"
    fi
    if [[ ${#kfiles[@]} -ne 1 ]]; then
        die "UKI/RPM: Expected exactly 1 vmlinuz-* on ESP, found ${#kfiles[@]}: ${kfiles[*]}"
    fi
    kernel_version="$(basename "${kfiles[0]}" | sed 's/^vmlinuz-//')"
    if [[ ! "${kernel_version}" =~ ^[0-9]+\.[0-9]+ ]]; then
        die "UKI/RPM: '${kernel_version}' does not look like a kernel version"
    fi
    info "UKI/RPM: Kernel version = ${kernel_version}"

    local uki_name="vmlinuz-${kernel_version}.efi"
    if [[ "$(basename "${kfiles[0]}")" != "vmlinuz-${kernel_version}" ]]; then
        die "UKI/RPM: kernel version parse mismatch: source='$(basename "${kfiles[0]}")' reconstructed='vmlinuz-${kernel_version}'"
    fi

    local efi_stub="${BOARD_ROOT}/usr/lib/systemd/boot/efi/linux${EFI_ARCH}.efi.stub"
    if [[ ! -f "${efi_stub}" ]]; then
        die "UKI/RPM: EFI stub not found at ${efi_stub}"
    fi

    local uki_output="${uki_temp_dir}/${uki_name}"
    info "UKI/RPM: Building UKI with ukify"

    sudo ukify build \
        --stub="${efi_stub}" \
        --linux="${kernel}" \
        --initrd="${initrd}" \
        --cmdline=@"${uki_temp_dir}/cmdline.txt" \
        --os-release=@"${osrelease}" \
        --output="${uki_output}"

    if [[ ! -f "${uki_output}" ]]; then
        die "UKI/RPM: ukify failed to produce ${uki_output}"
    fi

    info "UKI/RPM: UKI built successfully ($(du -h "${uki_output}" | cut -f1))"

    # Secure Boot chain: shim (BOOTX64.EFI, signed by Microsoft) →
    # systemd-boot (grubx64.efi, signed by Mariner CA) → UKI → addons.
    # Both shim and systemd-boot RPMs install to /boot/efi/EFI/BOOT/.
    local azl_efi_dir="${BOARD_ROOT}/boot/efi/EFI/BOOT"

    # Install shim as the default UEFI bootloader
    local shim_efi="${azl_efi_dir}/boot${EFI_ARCH}.efi"
    if [[ ! -f "${shim_efi}" ]]; then
        die "UKI/RPM: Shim not found at ${shim_efi}. Ensure the shim RPM is installed."
    fi

    sudo mkdir -p "${ESP_DIR}/EFI/BOOT"
    sudo cp "${shim_efi}" "${ESP_DIR}/EFI/BOOT/BOOT${EFI_ARCH^^}.EFI"
    info "UKI/RPM: Installed shim → EFI/BOOT/BOOT${EFI_ARCH^^}.EFI"

    # Install systemd-boot where shim expects its second-stage bootloader
    local sd_boot_efi="${azl_efi_dir}/grub${EFI_ARCH}.efi"
    if [[ ! -f "${sd_boot_efi}" ]]; then
        die "UKI/RPM: systemd-boot not found at ${sd_boot_efi}. Ensure the systemd-boot RPM is installed."
    fi

    sudo cp "${sd_boot_efi}" "${ESP_DIR}/EFI/BOOT/grub${EFI_ARCH}.efi"
    info "UKI/RPM: Installed systemd-boot → EFI/BOOT/grub${EFI_ARCH}.efi"

    # The kernel and initramfs are now embedded inside the UKI. Remove them from
    # the ESP to reclaim space.
    info "UKI/RPM: Cleaning up pre-UKI files from ESP"
    sudo rm -f "${ESP_DIR}"/flatcar/vmlinuz-a
    sudo rm -f "${ESP_DIR}"/flatcar/initramfs-a.img
    sudo rm -f "${ESP_DIR}"/boot/vmlinuz-* "${ESP_DIR}"/boot/System.map-* \
               "${ESP_DIR}"/boot/config-* "${ESP_DIR}"/boot/.vmlinuz-*.hmac 2>/dev/null || true
    # Also try top-level (kernel RPM installs to /boot/ which is the ESP mount root)
    sudo rm -f "${ESP_DIR}"/vmlinuz-* "${ESP_DIR}"/System.map-* \
               "${ESP_DIR}"/config-* "${ESP_DIR}"/.vmlinuz-*.hmac 2>/dev/null || true

    sudo mkdir -p "${ESP_DIR}/EFI/Linux"
    sudo cp "${uki_output}" "${ESP_DIR}/EFI/Linux/${uki_name}"
    info "UKI/RPM: Installed UKI → EFI/Linux/${uki_name}"

    sudo mkdir -p "${ESP_DIR}/loader"
    sudo tee "${ESP_DIR}/loader/loader.conf" > /dev/null <<-EOF
		timeout 0
		default ${uki_name}
	EOF
    info "UKI/RPM: Wrote loader/loader.conf"

    # Build and install the firstboot addon
    _uki_build_firstboot_addon "${ESP_DIR}" "${uki_name}"
    _uki_build_fips_addon "${ESP_DIR}"
    _uki_build_kdump_addon "${ESP_DIR}"
    _uki_build_debug_addon "${ESP_DIR}" "${uki_name}"

    # Clean up
    rm -rf "${uki_temp_dir}"
}

# Build a self-removing firstboot addon that triggers Ignition on first boot.
_uki_build_firstboot_addon() {
    local esp_dir="$1"
    local uki_name="$2"

    info "UKI/RPM: Building firstboot addon"

    local addon_dir="${esp_dir}/EFI/Linux/${uki_name}.extra.d"
    sudo mkdir -p "${addon_dir}"

    local firstboot_cmdline="flatcar.first_boot=detected"

    local fb_temp_dir
    fb_temp_dir=$(mktemp -d)

    echo "${firstboot_cmdline}" > "${fb_temp_dir}/firstboot-cmdline.txt"

    # efi_stub existence was already verified by the caller.
    local efi_stub="${BOARD_ROOT}/usr/lib/systemd/boot/efi/linux${EFI_ARCH}.efi.stub"

    sudo ukify build \
        --cmdline=@"${fb_temp_dir}/firstboot-cmdline.txt" \
        --stub="${efi_stub}" \
        --output="${fb_temp_dir}/firstboot.addon.efi"

    if [[ ! -f "${fb_temp_dir}/firstboot.addon.efi" ]]; then
        die "UKI/RPM: ukify failed to produce firstboot.addon.efi"
    fi

    sudo cp "${fb_temp_dir}/firstboot.addon.efi" "${addon_dir}/firstboot.addon.efi"
    info "UKI/RPM: Installed firstboot addon → EFI/Linux/${uki_name}.extra.d/firstboot.addon.efi"
    info "UKI/RPM: firstboot cmdline = ${firstboot_cmdline}"

    # Keep a template copy outside the auto-discovery directory so that
    # runtime tools (e.g., flatcar-reset) can restore it.
    local template_dir="${esp_dir}/acl/uki-addons"
    sudo mkdir -p "${template_dir}"
    sudo cp "${fb_temp_dir}/firstboot.addon.efi" "${template_dir}/firstboot.addon.efi"
    info "UKI/RPM: Saved firstboot addon template → acl/uki-addons/firstboot.addon.efi"

    rm -rf "${fb_temp_dir}"
}

# Build a reusable FIPS addon template for UKI systems.
_uki_build_fips_addon() {
    local esp_dir="$1"

    info "UKI/RPM: Building FIPS addon template"

    local template_dir="${esp_dir}/acl/uki-addons"
    sudo mkdir -p "${template_dir}"

    local fips_cmdline="fips=1"

    local fips_temp_dir
    fips_temp_dir=$(mktemp -d)

    echo "${fips_cmdline}" > "${fips_temp_dir}/fips-cmdline.txt"

    local efi_stub="${BOARD_ROOT}/usr/lib/systemd/boot/efi/linux${EFI_ARCH}.efi.stub"

    sudo ukify build \
        --cmdline=@"${fips_temp_dir}/fips-cmdline.txt" \
        --stub="${efi_stub}" \
        --output="${fips_temp_dir}/fips.addon.efi"

    if [[ ! -f "${fips_temp_dir}/fips.addon.efi" ]]; then
        die "UKI/RPM: ukify failed to produce fips.addon.efi"
    fi

    sudo cp "${fips_temp_dir}/fips.addon.efi" "${template_dir}/fips.addon.efi"
    info "UKI/RPM: Saved FIPS addon template -> acl/uki-addons/fips.addon.efi"

    rm -rf "${fips_temp_dir}"
}

# Build a reusable kdump addon template for UKI systems.
# NOT installed in the active .extra.d directory by default -> kdump
# must be explicitly enabled by copying this addon into
# EFI/Linux/acl.efi.extra.d/ on the ESP.
_uki_build_kdump_addon() {
    local esp_dir="$1"

    info "UKI/RPM: Building kdump addon template"

    local template_dir="${esp_dir}/acl/uki-addons"
    sudo mkdir -p "${template_dir}"

    local kdump_cmdline="crashkernel=256M"

    local kdump_temp_dir
    kdump_temp_dir=$(mktemp -d)

    echo "${kdump_cmdline}" > "${kdump_temp_dir}/kdump-cmdline.txt"

    local efi_stub="${BOARD_ROOT}/usr/lib/systemd/boot/efi/linux${EFI_ARCH}.efi.stub"

    sudo ukify build \
        --cmdline=@"${kdump_temp_dir}/kdump-cmdline.txt" \
        --stub="${efi_stub}" \
        --output="${kdump_temp_dir}/kdump.addon.efi"

    if [[ ! -f "${kdump_temp_dir}/kdump.addon.efi" ]]; then
        die "UKI/RPM: ukify failed to produce kdump.addon.efi"
    fi

    sudo cp "${kdump_temp_dir}/kdump.addon.efi" "${template_dir}/kdump.addon.efi"
    info "UKI/RPM: Saved kdump addon template -> acl/uki-addons/kdump.addon.efi"
    info "UKI/RPM: To enable kdump, copy to EFI/Linux/acl.efi.extra.d/kdump.addon.efi"

    rm -rf "${kdump_temp_dir}"
}

# Build an optional debug addon that appends extra kernel cmdline args.
# Only built when EXTRA_KERNEL_CMDLINE is set (e.g., via the Dev pipeline
# for boot performance profiling: systemd.log_level=debug, printk.devkmsg=on, etc.).
# The addon is installed in the active .extra.d directory so it takes effect
# on every boot of this image.
_uki_build_debug_addon() {
    local esp_dir="$1"
    local uki_name="$2"

    local extra_cmdline="${EXTRA_KERNEL_CMDLINE:-}"
    if [[ -z "${extra_cmdline}" ]]; then
        info "UKI/RPM: EXTRA_KERNEL_CMDLINE not set; skipping debug addon"
        return 0
    fi

    info "UKI/RPM: Building debug addon with extra cmdline"

    local addon_dir="${esp_dir}/EFI/Linux/${uki_name}.extra.d"
    sudo mkdir -p "${addon_dir}"

    local debug_temp_dir
    debug_temp_dir=$(mktemp -d)

    printf '%s\n' "${extra_cmdline}" > "${debug_temp_dir}/debug-cmdline.txt"

    local efi_stub="${BOARD_ROOT}/usr/lib/systemd/boot/efi/linux${EFI_ARCH}.efi.stub"

    sudo ukify build \
        --cmdline=@"${debug_temp_dir}/debug-cmdline.txt" \
        --stub="${efi_stub}" \
        --output="${debug_temp_dir}/debug.addon.efi"

    if [[ ! -f "${debug_temp_dir}/debug.addon.efi" ]]; then
        die "UKI/RPM: ukify failed to produce debug.addon.efi"
    fi

    sudo cp "${debug_temp_dir}/debug.addon.efi" "${addon_dir}/debug.addon.efi"
    info "UKI/RPM: Installed debug addon → EFI/Linux/${uki_name}.extra.d/debug.addon.efi"
    info "UKI/RPM: debug cmdline = ${extra_cmdline}"

    rm -rf "${debug_temp_dir}"
}

info "Installing UKI packages for target ${FLAGS_target}"
uki_install_rpm

# Mount the ESP and provision
ESP_DIR=
LOOP_DEV=

cleanup() {
    if [[ -d "${ESP_DIR}" ]]; then
        if mountpoint -q "${ESP_DIR}"; then
            sudo umount "${ESP_DIR}"
        fi
        rm -rf "${ESP_DIR}"
    fi
    if [[ -b "${LOOP_DEV}" ]]; then
        sudo losetup --detach "${LOOP_DEV}"
    fi
}
trap cleanup EXIT

info "Installing UKI ${FLAGS_target} in ${FLAGS_disk_image##*/}"
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
    sleep "$(bc <<<"scale=1; (2.0 ^ ${i}) / 2.0")"
done
if [[ -z ${MOUNTED} ]]; then
    failboat "${LOOP_DEV}p1 where art thou? udev has forsaken us!"
fi

# Provision systemd-boot + UKI onto the ESP
uki_provision_rpm "${ESP_DIR}"

cleanup
trap - EXIT
command_completed
