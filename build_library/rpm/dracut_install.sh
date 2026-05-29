# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Dracut initramfs generation for RPM/ACL builds.
# Sourced by build_image_util.sh — requires BUILD_LIBRARY_DIR, BUILD_DIR,
# and the rpm_mount_pseudofs / rpm_umount_pseudofs helpers from rpm_install.sh.

# Prepare chroot environment for dracut execution.
# Mounts pseudo-filesystems, creates udev/systemd symlinks, and sanitizes crypttab.
#
# Arguments:
#   $1 - root_fs_dir: path to the mounted root filesystem
_dracut_prepare_chroot() {
    local root_fs_dir="$1"

    # Mount required filesystems for dracut
    rpm_mount_pseudofs "${root_fs_dir}"

    # Ensure udevadm and systemd-udevd are findable
    # Azure Linux has udevadm at /usr/bin/udevadm and systemd-udevd at /usr/lib/systemd/systemd-udevd
    if [[ -x "${root_fs_dir}/usr/bin/udevadm" ]] && [[ ! -x "${root_fs_dir}/sbin/udevadm" ]]; then
        sudo ln -sf /usr/bin/udevadm "${root_fs_dir}/sbin/udevadm" 2>/dev/null || true
    fi
    if [[ -x "${root_fs_dir}/usr/lib/systemd/systemd-udevd" ]] && [[ ! -x "${root_fs_dir}/usr/bin/systemd-udevd" ]]; then
        sudo ln -sf /usr/lib/systemd/systemd-udevd "${root_fs_dir}/usr/bin/systemd-udevd" 2>/dev/null || true
        sudo ln -sf /usr/lib/systemd/systemd-udevd "${root_fs_dir}/sbin/systemd-udevd" 2>/dev/null || true
    fi
    # Also link udevd for compatibility
    if [[ -x "${root_fs_dir}/usr/lib/systemd/systemd-udevd" ]] && [[ ! -x "${root_fs_dir}/sbin/udevd" ]]; then
        sudo ln -sf /usr/lib/systemd/systemd-udevd "${root_fs_dir}/sbin/udevd" 2>/dev/null || true
    fi

    # If /etc/crypttab exists, ensure it doesn't contain fido2 entries
    # This prevents systemd-cryptsetup from requiring the fido2 module
    if [[ -f "${root_fs_dir}/etc/crypttab" ]]; then
        # Remove any fido2 entries if they exist
        sudo sed -i '/fido2-device=/d; /fido2-cid=/d' "${root_fs_dir}/etc/crypttab" 2>/dev/null || true
        die "Investigate further once this comes back."
    fi
}

# Patch bootengine dracut modules for Azure Linux compatibility.
# Removes unsupported modules, fixes ignition/disk-uuid/network-cleanup for ACL,
# and resolves systemd dependency cycles.
#
# Arguments:
#   $1 - root_fs_dir: path to the mounted root filesystem
_dracut_patch_bootengine_modules() {
    local root_fs_dir="$1"

    # Remove dracut modules that require hardware we don't have in VMs
    # This prevents systemd-cryptsetup from depending on fido2/pkcs11/tpm2-tss
    # which would cause dracut-systemd to fail
    for mod in 91fido2 91pkcs11 91tpm2-tss; do
        if [[ -d "${root_fs_dir}/usr/lib/dracut/modules.d/${mod}" ]]; then
            info "RPM mode: Removing dracut module ${mod} (not needed for VM boot)"
            sudo rm -rf "${root_fs_dir}/usr/lib/dracut/modules.d/${mod}"
        fi
    done

    # Remove bootengine's verity-generator - we use systemd's systemd-veritysetup-generator instead
    if [[ -d "${root_fs_dir}/usr/lib/dracut/modules.d/10verity-generator" ]]; then
        info "RPM mode: Removing bootengine 10verity-generator (using systemd-veritysetup-generator)"
        sudo rm -rf "${root_fs_dir}/usr/lib/dracut/modules.d/10verity-generator"
    fi

    # Remove bootengine's usr-generator - systemd-fstab-generator handles mount.usr= automatically
    # Our grub.cfg passes mount.usr=/dev/mapper/usr which systemd handles natively
    if [[ -d "${root_fs_dir}/usr/lib/dracut/modules.d/10usr-generator" ]]; then
        info "RPM mode: Removing bootengine 10usr-generator (using systemd-fstab-generator)"
        sudo rm -rf "${root_fs_dir}/usr/lib/dracut/modules.d/10usr-generator"
    fi

    # Remove Flatcar-specific and unsupported sections from ignition module-setup.sh
    local ignition_module_setup="${root_fs_dir}/usr/lib/dracut/modules.d/30ignition/module-setup.sh"
    if [[ -f "${ignition_module_setup}" ]]; then
        info "RPM mode: Removing Flatcar-specific sections from ignition module-setup.sh"
        # Remove cloud_aws_ebs_nvme_id (AWS-specific, doesn't exist in Azure Linux)
        sudo sed -i '/# Flatcar: add cloud_aws_ebs_nvme_id/,/\/usr\/lib\/udev\/cloud_aws_ebs_nvme_id"/d' "${ignition_module_setup}"
        # Remove clevis binding section (clevis not available in Azure Linux)
        sudo sed -i '/# Needed for clevis binding/,/tpm2_create$/d' "${ignition_module_setup}"
        # Remove s390x z/VM section (not supported)
        sudo sed -i "/# Required by s390x's z\/VM installation/,/inst_multiple -o chccwdev vmur$/d" "${ignition_module_setup}"
        # Remove clevis symlink entries from the executable wrapper loop
        sudo sed -i '/\/usr\/bin\/clevis\*,\\$/d' "${ignition_module_setup}"
        sudo sed -i '/\/usr\/libexec\/clevis\*\\$/d' "${ignition_module_setup}"
        # TEMPORARY: Remove jose/luksmeta wrapper entries — these packages are not
        # currently shipped in ACL (Clevis/Tang disk encryption is not supported).
        # TODO: Re-enable when Clevis/Tang support is added back.
        sudo sed -i '/\/usr\/bin\/jose,\\$/d' "${ignition_module_setup}"
        sudo sed -i '/\/usr\/bin\/luksmeta,\\$/d' "${ignition_module_setup}"
        # Fix trailing comma on systemd-reply-password (now last entry after removing clevis)
        sudo sed -i 's|/usr/lib/systemd/systemd-reply-password,\\|/usr/lib/systemd/systemd-reply-password\\|' "${ignition_module_setup}"
        # Replace /usr/bin/xfs_db and xfs_repair with /usr/sbin versions (Azure Linux path)
        sudo sed -i 's|/usr/bin/xfs_db,\\|/usr/sbin/xfs_db,\\|' "${ignition_module_setup}"
        sudo sed -i 's|/usr/bin/xfs_repair,\\|/usr/sbin/xfs_repair,\\|' "${ignition_module_setup}"
        # NOTE: Keep the /sysusr/usr wrapper paths! systemd-fstab-generator mounts
        # the verity /usr to /sysusr/usr, so wrappers pointing there are correct.
    fi

    # Remove cgpt from 30disk-uuid module (cgpt not available in Azure Linux)
    local disk_uuid_script="${root_fs_dir}/usr/lib/dracut/modules.d/30disk-uuid/disk-uuid.sh"
    local disk_uuid_module_setup="${root_fs_dir}/usr/lib/dracut/modules.d/30disk-uuid/module-setup.sh"
    if [[ -f "${disk_uuid_script}" ]]; then
        info "RPM mode: Removing cgpt call from disk-uuid.sh"
        sudo sed -i '/\/usr\/bin\/cgpt repair/d' "${disk_uuid_script}"
    fi
    if [[ -f "${disk_uuid_module_setup}" ]]; then
        info "RPM mode: Removing cgpt from 30disk-uuid/module-setup.sh"
        sudo sed -i '/cgpt$/d' "${disk_uuid_module_setup}"
    fi

    # Patch disk-uuid.service to order before systemd-veritysetup@usr.service
    # Bootengine's disk-uuid.service has "Before=verity-setup.service" for Flatcar's custom verity,
    # but ACL uses systemd's standard systemd-veritysetup-generator which creates
    # systemd-veritysetup@usr.service. Without this ordering, disk-uuid's sgdisk call
    # can cause udev activity that races with/terminates the verity setup process.
    local disk_uuid_service="${root_fs_dir}/usr/lib/dracut/modules.d/30disk-uuid/disk-uuid.service"
    if [[ -f "${disk_uuid_service}" ]]; then
        info "RPM mode: Adding Before=systemd-veritysetup@usr.service to disk-uuid.service"
        sudo sed -i 's/Before=ignition-setup.service ignition-disks.service verity-setup.service/Before=ignition-setup.service ignition-disks.service verity-setup.service systemd-veritysetup@usr.service/' "${disk_uuid_service}"
    fi

    # Patch ignition-setup.sh for systemd-based initramfs
    # In upstream Flatcar, initramfs /usr is a tmpfs that can be remounted rw.
    # In our systemd-native setup, /usr may already be mounted from verity device.
    # The "mount -o remount,rw" would fail because:
    # 1. /usr is not mounted (just initramfs tmpfs) - remount fails
    # 2. /usr is verity-protected - can't be made writable
    # Solution: Create /usr/lib/ignition without remounting - it's on initramfs tmpfs
    local ignition_setup_script="${root_fs_dir}/usr/lib/dracut/modules.d/30ignition/ignition-setup.sh"
    if [[ -f "${ignition_setup_script}" ]]; then
        info "RPM mode: Patching ignition-setup.sh - remove remount (initramfs /usr is already writable)"
        # Remove the remount command - initramfs /usr is tmpfs and already writable
        # The mkdir will work on the initramfs tmpfs /usr
        sudo sed -i '/mount -o remount,rw \/usr/d' "${ignition_setup_script}"
    fi

    # Remove bootengine's sysusr-usr-revdeps.conf which creates cyclic dependencies
    # Bootengine expects sysusr-usr.mount for its custom boot flow, and systemd-fstab-generator
    # creates exactly this unit! So the dependencies are correct.
    # Only remove sysusr-usr-revdeps.conf which creates extra cryptsetup dependencies we don't need.
    local sysusr_revdeps="${root_fs_dir}/usr/lib/dracut/modules.d/30ignition/sysusr-usr-revdeps.conf"
    if [[ -f "${sysusr_revdeps}" ]]; then
        info "RPM mode: Removing sysusr-usr-revdeps.conf (cryptsetup dep not needed)"
        sudo rm -f "${sysusr_revdeps}"
    fi
    # Also remove the inst_simple lines from module-setup.sh that install it (spans 2 lines)
    if [[ -f "${ignition_module_setup}" ]]; then
        # Remove both lines: "inst_simple ... sysusr-usr-revdeps.conf \" and the continuation line
        sudo sed -i '/inst_simple.*sysusr-usr-revdeps\.conf/,/sysusr-usr\.conf"/d' "${ignition_module_setup}"
    fi

    # NOTE: Keep sysusr-usr.mount dependencies! systemd-fstab-generator creates this unit
    # to mount /dev/mapper/usr at /sysusr/usr. Services need to wait for it.

    # Fix cyclic dependency: ignition-setup.service → sysusr-usr.mount → local-fs-pre.target → ignition-setup.service
    # The ignition-generator creates services with "Requires/Before=local-fs-pre.target" but
    # sysusr-usr.mount (created by systemd-fstab-generator) has ordering with local-fs-pre.target.
    # Solution: Remove the local-fs-pre.target dependency from ignition services.
    # They only need sysusr-usr.mount (for /usr access), not local-fs-pre.target.
    local ignition_generator="${root_fs_dir}/usr/lib/dracut/modules.d/30ignition/ignition-generator"
    if [[ -f "${ignition_generator}" ]]; then
        info "RPM mode: Patching ignition-generator to remove local-fs-pre.target cycle"
        # Remove the Requires=local-fs-pre.target and Before=local-fs-pre.target lines
        # from both ignition-setup-pre.service and ignition-setup.service generation
        sudo sed -i '/Requires=local-fs-pre.target/d' "${ignition_generator}"
        sudo sed -i '/Before=local-fs-pre.target/d' "${ignition_generator}"
    fi

    # Also patch static ignition service files that have local-fs-pre.target dependencies
    local ignition_mod_dir="${root_fs_dir}/usr/lib/dracut/modules.d/30ignition"
    for service_file in "${ignition_mod_dir}"/ignition-*.service; do
        if [[ -f "${service_file}" ]] && grep -q "local-fs-pre.target" "${service_file}"; then
            info "RPM mode: Patching $(basename "${service_file}") to remove local-fs-pre.target"
            sudo sed -i '/Requires=local-fs-pre.target/d' "${service_file}"
            sudo sed -i '/Before=local-fs-pre.target/d' "${service_file}"
        fi
    done

    # Patch network-cleanup.service to stop before initrd-cleanup while /usr/bin/ip is accessible
    # The service runs in initrd and uses /usr/bin/ip in ExecStop. Without this fix, the stop
    # happens after switch-root when the initrd binaries are gone, causing exit code 203/EXEC.
    # We add `-` prefix to ExecStop to make failures non-fatal (binary may be gone during switch-root)
    local network_cleanup_svc="${root_fs_dir}/usr/lib/dracut/modules.d/03flatcar-network/network-cleanup.service"
    if [[ -f "${network_cleanup_svc}" ]]; then
        info "RPM mode: Patching network-cleanup.service for initrd stop handling"
        # Add ConditionPathExists to only run in initrd
        sudo sed -i '/ConditionKernelCommandLine=!netroot/a # Only run in initrd\nConditionPathExists=/etc/initrd-release' "${network_cleanup_svc}"
        # Add initrd-cleanup.service and initrd-switch-root.service to Before= line
        # This ensures ExecStop runs before the switch-root happens and before cleanup
        sudo sed -i 's/Before=systemd-networkd.service initrd-switch-root.target/Before=systemd-networkd.service initrd-switch-root.target initrd-switch-root.service initrd-cleanup.service/' "${network_cleanup_svc}"
        # Add initrd-cleanup.service and initrd-switch-root.service to Conflicts= line
        # Conflicts triggers stop when these units start
        sudo sed -i 's/Conflicts=initrd-switch-root.target/Conflicts=initrd-switch-root.target initrd-switch-root.service initrd-cleanup.service/' "${network_cleanup_svc}"
        # Add StopWhenUnneeded=true to end of [Unit] section so service stops as soon as nothing needs it
        sudo sed -i '/^ConditionPathExists=\/etc\/initrd-release$/a StopWhenUnneeded=true' "${network_cleanup_svc}"
        # Make ExecStop commands optional with - prefix (won't fail if binary missing during switch-root)
        sudo sed -i 's|ExecStop=/usr/bin/ip|ExecStop=-/usr/bin/ip|g' "${network_cleanup_svc}"

        # Also install network-cleanup.service on the real root filesystem
        # This is needed because PartOf=systemd-networkd.service causes systemd to try
        # stopping the service after switch-root. With the service file on real root,
        # the stop will succeed using the real /usr/bin/ip.
        info "RPM mode: Installing network-cleanup.service on real root for post-switch-root stop"
        sudo cp "${network_cleanup_svc}" "${root_fs_dir}/usr/lib/systemd/system/network-cleanup.service"
    fi

    # Patch initrd-setup-root-after-ignition for ACL:
    # - Tolerate missing FLATCAR_BOARD (ACL os-release doesn't include it, script uses set -u)
    # - Remove download_and_verify function and all download logic (ACL doesn't use Flatcar's
    #   update server for sysext downloads)
    # - Keep the enabled-sysext.conf loop for symlink management, just remove download fallback
    local setup_root_after="${root_fs_dir}/usr/lib/dracut/modules.d/99setup-root/initrd-setup-root-after-ignition"
    if [[ -f "${setup_root_after}" ]]; then
        info "RPM mode: Patching initrd-setup-root-after-ignition for ACL"
        # Fix unbound FLATCAR_BOARD variable
        sudo sed -i 's/echo "${FLATCAR_BOARD}"/echo "${FLATCAR_BOARD:-}"/' "${setup_root_after}"
        # Remove the download_and_verify function definition and its usage comment
        sudo sed -i '/^function download_and_verify()/,/^}$/d' "${setup_root_after}"
        sudo sed -i '/^# Note: don.t use as.*download_and_verify/d' "${setup_root_after}"
        # Remove the OEM sysext download fallback (else branch that calls download_and_verify)
        sudo sed -i '/echo "Did not find.*nor.*downloading"/,/^    fi$/d' "${setup_root_after}"
        # Clean up the now-empty else: if "  else" is immediately followed by "  fi", drop the else
        sudo sed -i '/^  else$/{N;/\n  fi$/s/^  else\n//}' "${setup_root_after}"
        # Remove the download fallback inside the enabled-sysext.conf loop (keep symlink management)
        sudo sed -i '/if \[ ! -e "\/sysroot\/\${ACTIVE_EXT}" \]/,/^  fi$/d' "${setup_root_after}"
        # Remove any remaining systemctl network start lines (only used for download)
        sudo sed -i '/systemctl start --quiet systemd-networkd systemd-resolved/d' "${setup_root_after}"
    fi
    
    # Patch bootengine's 99setup-root scripts to use the distribution share directory
    # instead of the Flatcar-specific /usr/share/flatcar path
    local setup_root_dir="${root_fs_dir}/usr/lib/dracut/modules.d/99setup-root"
    for script in initrd-setup-root initrd-setup-root-after-ignition; do
        if [[ -f "${setup_root_dir}/${script}" ]]; then
            info "RPM mode: Patching ${script} - replacing /usr/share/flatcar with ${DISTRO_SHARE_DIR}"
            sudo sed -i "s|/usr/share/flatcar|${DISTRO_SHARE_DIR}|g" "${setup_root_dir}/${script}"
        fi
    done
}

# Install new initramfs assets that dracut will pick up.
# Creates the sysroot-oem dracut module, flatcar-tmpfiles stub, tmpfiles.d configs,
# and systemd drop-ins for verity device timing. Must run BEFORE dracut execution.
#
# Arguments:
#   $1 - root_fs_dir: path to the mounted root filesystem
_dracut_install_initramfs_assets() {
    local root_fs_dir="$1"

    # Create sysroot-oem.mount unit matching Flatcar's diskless-generator behavior.
    # This unit is created but NOT added to initrd-root-fs.target.requires, so it
    # won't be automatically started. Instead, ignition-files.service has:
    #   ExecStartPre=-systemctl start sysroot-oem.mount
    # which starts it when needed (the - prefix means failure is ignored).
    #
    # Note: cl.ignition.oem.regular test is excluded from ACL because it uses
    # the old /usr/share/oem path which requires Ignition patch 0020's umount
    # path translation that we don't have. cl.ignition.oem.regular.new uses
    # the new /oem path and works correctly.
    info "RPM mode: Creating sysroot-oem.mount for OEM partition handling"
    local sysroot_oem_dracut_module="${root_fs_dir}/usr/lib/dracut/modules.d/35sysroot-oem"
    sudo mkdir -p "${sysroot_oem_dracut_module}"
    cat <<'EOF' | sudo tee "${sysroot_oem_dracut_module}/sysroot-oem.mount" > /dev/null
# Matches Flatcar's diskless-generator behavior
# (Ignition's OEM mounting can also (de)activate the unit)
[Mount]
What=/dev/disk/by-label/OEM
Where=/sysroot/oem
Type=auto
Options=nodev
EOF

    # Create module-setup.sh to install sysroot-oem.mount into initramfs
    cat <<'SETUP_EOF' | sudo tee "${sysroot_oem_dracut_module}/module-setup.sh" > /dev/null
#!/bin/bash
# dracut module for sysroot-oem mount unit

check() {
    return 0
}

depends() {
    return 0
}

install() {
    inst_simple "${moddir}/sysroot-oem.mount" "${systemdsystemunitdir}/sysroot-oem.mount"
}
SETUP_EOF
    sudo chmod +x "${sysroot_oem_dracut_module}/module-setup.sh"

    # Install acl-selinux-toggle dracut module.
    # Queries Azure IMDS for a selinux tag and applies the mode (permissive
    # or enforcing) before switch-root so SELinux is set before real-root
    # services start.
    info "RPM mode: Creating acl-selinux-toggle dracut module for IMDS SELinux toggling"
    local selinux_toggle_module="${root_fs_dir}/usr/lib/dracut/modules.d/99acl-selinux-toggle"
    sudo mkdir -p "${selinux_toggle_module}"
    sudo cp "${BUILD_LIBRARY_DIR}/rpm/additional_files/dracut-acl-selinux-toggle/module-setup.sh" \
        "${selinux_toggle_module}/module-setup.sh"
    sudo cp "${BUILD_LIBRARY_DIR}/rpm/additional_files/dracut-acl-selinux-toggle/acl-selinux-toggle.sh" \
        "${selinux_toggle_module}/acl-selinux-toggle.sh"
    sudo cp "${BUILD_LIBRARY_DIR}/rpm/additional_files/dracut-acl-selinux-toggle/acl-selinux-toggle.service" \
        "${selinux_toggle_module}/acl-selinux-toggle.service"
    sudo chmod +x "${selinux_toggle_module}/module-setup.sh"
    sudo chmod +x "${selinux_toggle_module}/acl-selinux-toggle.sh"

    # NOTE: /etc overlay is handled by bootengine's 99setup-root/initrd-setup-root
    # We need to create the required files BEFORE dracut runs so they get included in initramfs

    # Create flatcar-tmpfiles stub script required by bootengine's initrd-setup-root
    # Must be created before dracut so it gets included in initramfs
    info "RPM mode: Creating flatcar-tmpfiles stub for bootengine compatibility"
    sudo mkdir -p "${root_fs_dir}/usr/sbin"
    cat <<EOF | sudo tee "${root_fs_dir}/usr/sbin/flatcar-tmpfiles" > /dev/null
#!/bin/bash
# Stub for flatcar-tmpfiles - Azure Linux handles user/group creation differently
# This script is called by bootengine's initrd-setup-root to initialize shadow database
# In Azure Linux, the shadow database is pre-populated by RPM packages
SYSROOT="\${1:-/sysroot}"
# Ensure essential directories exist
mkdir -p "\${SYSROOT}/etc"
# Ensure basic shadow files exist (if not already present)
for f in passwd group shadow gshadow; do
    if [[ ! -f "\${SYSROOT}/etc/\${f}" ]] && [[ -f "\${SYSROOT}${DISTRO_SHARE_DIR}/etc/\${f}" ]]; then
        cp "\${SYSROOT}${DISTRO_SHARE_DIR}/etc/\${f}" "\${SYSROOT}/etc/\${f}"
    fi
done
exit 0
EOF
    sudo chmod +x "${root_fs_dir}/usr/sbin/flatcar-tmpfiles"

    # Create tmpfiles.d configs required by bootengine's initrd-setup-root
    # These are minimal configs - Azure Linux already provides most paths via its own tmpfiles
    # We only include entries not already in Azure Linux's standard tmpfiles configs
    info "RPM mode: Creating tmpfiles.d configs for bootengine compatibility"
    local tmpfiles_dir="${root_fs_dir}/usr/lib/tmpfiles.d"
    sudo mkdir -p "${tmpfiles_dir}"

    # baselayout.conf - only entries not in Azure Linux's var.conf/tmp.conf
    cat <<'EOF' | sudo tee "${tmpfiles_dir}/baselayout.conf" > /dev/null
# Bootengine compatibility - journal directory for early boot
d /var/log/journal 0755 root root -
d /var/log/journal/remote 0755 root root -
d /run/lock 0755 root root -
# Mount points required by bootengine
d /var/log/audit 0755 root root -
d /boot 0755 root root -
d /oem 0755 root root -
d /media 0755 root root -
EOF

    # baselayout-etc.conf - Flatcar ships this in its baselayout package.
    # The "d /etc" rule causes systemd-tmpfiles label_fix_full() on /etc,
    # writing the correct etc_t label to the overlay upper dir.
    cat <<'EOF' | sudo tee "${tmpfiles_dir}/baselayout-etc.conf" > /dev/null
d   /etc                              -   -   -   -   -
EOF

    # baselayout-usr.conf - required by bootengine's initrd-setup-root which
    # explicitly runs: systemd-tmpfiles --create baselayout-usr.conf
    # Empty because /usr/local dirs are created at build time and /usr is read-only,
    # so tmpfiles would only trigger SELinux relabel warnings.
    cat <<'EOF' | sudo tee "${tmpfiles_dir}/baselayout-usr.conf" > /dev/null
# Intentionally empty - /usr/local dirs exist at build time; /usr is read-only
EOF

    # baselayout-home.conf - only core user home (not /home itself)
    cat <<'EOF' | sudo tee "${tmpfiles_dir}/baselayout-home.conf" > /dev/null
# Core user home directory
d /home/core 0700 core core -
EOF

    # base_image_var.conf - only entries not in Azure Linux's var.conf
    cat <<'EOF' | sudo tee "${tmpfiles_dir}/base_image_var.conf" > /dev/null
# Additional /var structure for bootengine
d /var/lib/systemd/coredump 0755 root root -
EOF

    # Remove baselayout-ldso.conf — it creates a symlink /etc/ld.so.conf -> ../usr/lib/ld.so.conf
    # but Azure Linux's glibc RPM installs /etc/ld.so.conf as a regular file (with different
    # content and layout). The symlink target doesn't exist, producing a dead link.
    sudo rm -f "${tmpfiles_dir}/baselayout-ldso.conf"

    # Note: chrony tmpfiles (var/lib/chrony dir, chrony.keys copy) are installed
    # by the oem-azure sysext via manglefs.sh

    # Create systemd drop-ins for verity device timing
    # These ensure udev has finished device enumeration before verity setup runs
    local systemd_dropin_dir="${root_fs_dir}/usr/lib/systemd/system"

    # Drop-in for dev-mapper-usr.device - disable job timeout
    info "RPM mode: Creating drop-in for dev-mapper-usr.device (no job timeout)"
    sudo mkdir -p "${systemd_dropin_dir}/dev-mapper-usr.device.d"
    cat <<'EOF' | sudo tee "${systemd_dropin_dir}/dev-mapper-usr.device.d/no-job-timeout.conf" > /dev/null
[Unit]
# Disable job timeout to allow verity setup to wait for slow device enumeration
JobRunningTimeoutSec=infinity
EOF
}

# Generate initramfs using dracut inside the root filesystem chroot.
# Orchestrates chroot preparation, bootengine module patching, asset installation,
# and dracut execution to produce the initramfs.
#
# Arguments:
#   $1 - root_fs_dir: path to the mounted root filesystem
#   $2 - kernel_version: kernel version string (e.g. 6.6.112.1-2.azl3)
#   $3 - boot_fc_path: path to /boot/flatcar inside root_fs_dir
generate_initramfs_dracut() {
    local root_fs_dir="$1"
    local kernel_version="$2"
    local boot_fc_path="$3"

    if ! [[ -x "${root_fs_dir}/usr/bin/dracut" ]] && ! [[ -x "${root_fs_dir}/sbin/dracut" ]]; then
        die "RPM mode: dracut not found - cannot generate initramfs required for Azure Linux kernel"
    fi

    info "RPM mode: Generating initramfs with dracut"

    _dracut_prepare_chroot "${root_fs_dir}"
    _dracut_patch_bootengine_modules "${root_fs_dir}"
    _dracut_install_initramfs_assets "${root_fs_dir}"

    # Create dracut config to work around issues in chroot environment
    # We rely on standard systemd-udevd module to include libudev.so
    sudo mkdir -p "${root_fs_dir}/etc/dracut.conf.d"
    sudo cp "${BUILD_LIBRARY_DIR}/rpm/additional_files/99-acl.conf" "${root_fs_dir}/etc/dracut.conf.d/99-acl.conf"
    sudo cp "${BUILD_LIBRARY_DIR}/rpm/additional_files/99-fips.conf" "${root_fs_dir}/etc/dracut.conf.d/99-fips.conf"

    # Create a wrapper script that sets up the environment properly for dracut
    sudo cp "${BUILD_LIBRARY_DIR}/rpm/additional_files/run-dracut.sh" "${root_fs_dir}/tmp/run-dracut.sh"
    sudo chmod +x "${root_fs_dir}/tmp/run-dracut.sh"

    # Run dracut via the wrapper script with verbose logging
    # Output goes to log file only to reduce noise in build output
    local dracut_log="${root_fs_dir}/tmp/dracut-verbose.log"
    info "RPM mode: Running dracut (log: ${dracut_log})..."
    local initramfs_path="${boot_fc_path}/initramfs-a.img"
    # For chroot, use path relative to chroot environment
    local initramfs_chroot_path="/boot/flatcar/initramfs-a.img"
    sudo chroot "${root_fs_dir}" /tmp/run-dracut.sh \
      --force \
      --no-hostonly \
      --no-early-microcode \
      --verbose \
      --kver "${kernel_version}" \
        "${initramfs_chroot_path}" > "${dracut_log}" 2>&1 || {
        error "RPM mode: dracut failed. Log saved to ${dracut_log}"
        error "Last 50 lines of dracut log:"
        tail -50 "${dracut_log}" | while read line; do error "  $line"; done
        # Copy dracut log to build output for analysis
        if cp "${dracut_log}" "${BUILD_DIR}/dracut-verbose.log" 2>/dev/null; then
            error "RPM mode: dracut log saved to ${BUILD_DIR}/dracut-verbose.log"
        fi
        # Clean up before failing
        sudo rm -f "${root_fs_dir}/tmp/run-dracut.sh"
        rpm_umount_pseudofs "${root_fs_dir}"
        die "RPM mode: dracut initramfs generation failed"
      }

    # Copy dracut log to build output for analysis
    if [[ -f "${dracut_log}" ]] && cp "${dracut_log}" "${BUILD_DIR}/dracut-verbose.log" 2>/dev/null; then
        info "RPM mode: dracut log saved to ${BUILD_DIR}/dracut-verbose.log"
    fi

    # Clean up wrapper script
    sudo rm -f "${root_fs_dir}/tmp/run-dracut.sh"

    # Unmount filesystems
    rpm_umount_pseudofs "${root_fs_dir}"

    if [[ -f "${initramfs_path}" ]]; then
      info "RPM mode: initramfs generated successfully"
      ls -la "${initramfs_path}"
    else
      die "RPM mode: initramfs was not generated at ${initramfs_path}"
    fi
}
