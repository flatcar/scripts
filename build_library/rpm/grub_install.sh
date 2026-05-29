# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

grub_install_rpm() {
    # Map EFI target to RPM architecture for package selection
    local rpm_arch
    case "${FLAGS_target}" in
        x86_64-efi) rpm_arch="x86_64" ;;
        arm64-efi)  rpm_arch="aarch64" ;;
    esac

    case "${FLAGS_target}" in
        x86_64-efi|arm64-efi)
            info "RPM mode: Using Azure Linux pre-built EFI binaries"
            
            # In RPM mode, install grub packages to BOARD_ROOT (SDK chroot) using dnf
            # These are build-time tools and EFI binaries, not runtime packages for the image
            info "RPM mode: Installing grub2 and shim to BOARD_ROOT using dnf"

            # Source rpm_install functions
            . "${BUILD_LIBRARY_DIR}/rpm/rpm_install.sh" || die "Failed to source rpm_install.sh"

            # Setup repositories
            rpm_staging=$(rpm_get_staging_dir)
            grub_local_cache="${RPM_LOCAL_CACHE:-${rpm_staging}}"

            # Note: grub/shim packages should already be downloaded by finish_image_rpm()
            # No need to call rpm_download_packages again - the packages are in the local cache

            # Install grub packages to BOARD_ROOT from local RPM files
            # We only need the grub binaries and modules, not runtime dependencies
            info "RPM mode: Installing grub2 and shim to BOARD_ROOT from local RPMs"

            # Find grub RPMs in local cache — filter by target architecture
            # so arm64 builds pick aarch64 RPMs and x86 builds pick x86_64 RPMs.
            grub_rpms=()
            for pkg in grub2 grub2-efi grub2-efi-binary shim; do
                rpm_file=$(find "${grub_local_cache}" -name "${pkg}-[0-9]*.${rpm_arch}.rpm" | sort -V | tail -1)
                if [[ -z "${rpm_file}" ]]; then
                    die "RPM file not found for package: ${pkg} (${rpm_arch}) in ${grub_local_cache}"
                fi
                grub_rpms+=("${rpm_file}")
            done

            # Import GPG key and install packages
            rpm_import_gpg_key "${BOARD_ROOT}"
            rpm_install_local_packages "${BOARD_ROOT}" "${grub_rpms[@]}" || die "Failed to install grub packages to BOARD_ROOT"

            ;;
        i386-pc)
            # RPM mode: Skip BIOS boot - Azure Linux VMs use UEFI only
            # The grub2-pc RPM has modules but no pre-built core.img
            # grub-bios-setup requires core.img which would need grub-mkimage
            info "RPM mode: Skipping BIOS boot installation (UEFI only)"
            ;;
        x86_64-xen)
            # RPM mode: Skip Xen bootloader (not typically used with Azure Linux)
            info "RPM mode: Skipping Xen bootloader installation"
            ;;
    esac

}

grub_provision_rpm() {
    local ESP_DIR="$1"

    case "${FLAGS_target}" in
        x86_64-efi|arm64-efi)
            info "RPM mode: Using Azure Linux pre-built EFI binaries"

            # Azure Linux installs EFI files to /boot/efi/EFI/BOOT/
            azl_efi_dir="${BOARD_ROOT}/boot/efi/EFI/BOOT"

            # Copy Azure Linux grub EFI binary (use sudo for file tests since files are root-owned)
            if sudo test -f "${azl_efi_dir}/grub${EFI_ARCH}.efi"; then
                info "Copying Azure Linux grub${EFI_ARCH}.efi"
                sudo cp "${azl_efi_dir}/grub${EFI_ARCH}.efi" "${ESP_DIR}/${GRUB_IMAGE}"
            else
                die "Azure Linux grub${EFI_ARCH}.efi not found at ${azl_efi_dir}"
            fi

            # Copy Azure Linux shim (bootx64.efi)
            if sudo test -f "${azl_efi_dir}/boot${EFI_ARCH}.efi"; then
                info "Copying Azure Linux boot${EFI_ARCH}.efi (shim)"
                sudo cp "${azl_efi_dir}/boot${EFI_ARCH}.efi" "${ESP_DIR}/EFI/boot/boot${EFI_ARCH}.efi"
            else
                die "Azure Linux boot${EFI_ARCH}.efi (shim) not found at ${azl_efi_dir}"
            fi

            # Copy Azure Linux MokManager (mmx64.efi)
            if sudo test -f "${azl_efi_dir}/mm${EFI_ARCH}.efi"; then
                info "Copying Azure Linux mm${EFI_ARCH}.efi (MokManager)"
                sudo cp "${azl_efi_dir}/mm${EFI_ARCH}.efi" "${ESP_DIR}/EFI/boot/mm${EFI_ARCH}.efi"
            else
                warn "Azure Linux mm${EFI_ARCH}.efi (MokManager) not found at ${azl_efi_dir}"
            fi

            # Azure Linux GRUB doesn't have embedded memdisk, place grub.cfg on ESP directly
            # Place it in multiple locations for compatibility
            info "RPM mode: Writing grub.cfg to ESP filesystem"

            # Find the kernel name on the ESP to inject into grub.cfg
            kernel_name=$(ls "${ESP_DIR}"/flatcar/vmlinuz-a 2>/dev/null | grep -v ".hmac" | head -1 | xargs basename 2>/dev/null)
            if [[ -z "${kernel_name}" ]]; then
                warn "RPM mode: No kernel found on ESP, grub.cfg will use dynamic detection"
                kernel_name=""
            else
                info "RPM mode: Found kernel ${kernel_name} on ESP"
            fi

            # Generate grub.cfg - inject kernel name and verity settings
            # Use grub_hybrid.cfg template which includes initrd support
            sed_cmds=()
            if [[ ${FLAGS_verity} -eq ${FLAGS_TRUE} ]]; then
                # For RPM mode with verity, use systemd-native usrhash= parameter
                # systemd-veritysetup-generator will create /dev/mapper/usr from this
                sed_cmds+=(-e 's/@@MOUNTUSR@@/mount.usr=\/dev\/mapper\/usr/')

                # Read and inject the verity hash if available
                if [[ -n "${FLAGS_verity_hash}" && -f "${FLAGS_verity_hash}" ]]; then
                    usr_hash=$(cat "${FLAGS_verity_hash}")
                    info "RPM mode: Injecting verity hash ${usr_hash}"
                    sed_cmds+=(-e "s/@@USRHASH@@/${usr_hash}/")
                else
                    warn "RPM mode: Verity enabled but no hash file provided"
                    sed_cmds+=(-e 's/@@USRHASH@@//')
                fi
            else
                sed_cmds+=(-e 's/@@MOUNTUSR@@/mount.usr/')
                sed_cmds+=(-e 's/@@USRHASH@@//')
            fi
            if [[ -n "${kernel_name}" ]]; then
                sed_cmds+=(-e "s|@@KERNEL@@|/flatcar/${kernel_name}|")
            fi

            cat "${BUILD_LIBRARY_DIR}/rpm/grub.cfg" | sed "${sed_cmds[@]}" > "${GRUB_TEMP_DIR}/grub.cfg"

            sudo cp "${GRUB_TEMP_DIR}/grub.cfg" "${ESP_DIR}/EFI/boot/grub.cfg"
            sudo mkdir -p "${ESP_DIR}/boot/grub2"
            sudo cp "${GRUB_TEMP_DIR}/grub.cfg" "${ESP_DIR}/boot/grub2/grub.cfg"
            # # Also keep it in the flatcar location for compatibility
            # sudo cp "${GRUB_TEMP_DIR}/grub.cfg" "${ESP_DIR}/flatcar/grub/grub.cfg"

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
            # RPM mode: Skip BIOS boot - Azure Linux VMs use UEFI only
            # The grub2-pc RPM has modules but no pre-built core.img
            # grub-bios-setup requires core.img which would need grub-mkimage
            info "RPM mode: Skipping BIOS boot installation (UEFI only)"
            ;;
        x86_64-xen)
            # RPM mode: Skip Xen bootloader (not typically used with Azure Linux)
            info "RPM mode: Skipping Xen bootloader installation"
            ;;
    esac
}
