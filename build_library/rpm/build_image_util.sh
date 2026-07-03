# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

source "${BUILD_LIBRARY_DIR}/rpm/package_catalog.sh" || exit 1
source "${BUILD_LIBRARY_DIR}/rpm/rpm_install.sh" || exit 1
source "${BUILD_LIBRARY_DIR}/rpm/dracut_install.sh" || exit 1

run_localedef() {
  local root_fs_dir="$1" loader=()

  # For RPM mode, Azure Linux glibc already includes pre-compiled C.utf8 locale
  # at /usr/lib/locale/C.utf8, so we can skip running localedef
  info "Confirming presence of C.UTF-8 locale..."
  if [[ -d "${root_fs_dir}/usr/lib/locale/C.utf8" ]]; then
    info "C.utf8 locale already present from glibc RPM, skipping localedef"
    return 0
  fi

  error "C.utf8 locale not found in RPM mode, investigate."
  exit 1
}

# List packages installed from RPM database
# Returns non-zero if no packages found (to fail fast during build)
image_packages_portage() {
    local root_fs_dir="$1"

    local dbpath="${root_fs_dir}/var/lib/rpm"
    local pkg_count=0

    if [[ -d "${dbpath}" ]]; then
        pkg_count=$(rpm_query_packages "${root_fs_dir}" | wc -l)
        info "RPM database at ${dbpath}: ${pkg_count} packages"
        rpm_query_packages "${root_fs_dir}"
    elif [[ -n "${BUILD_DIR:-}" && -f "${BUILD_DIR}/.rpm_packages_installed.txt" ]]; then
        # Fallback: use the backup file created during installation
        pkg_count=$(wc -l < "${BUILD_DIR}/.rpm_packages_installed.txt" 2>/dev/null || echo 0)
        info "Using backup file ${BUILD_DIR}/.rpm_packages_installed.txt: ${pkg_count} packages"
        cat "${BUILD_DIR}/.rpm_packages_installed.txt"
    else
        error "RPM database not found and no backup available for ${root_fs_dir}"
        return 1
    fi

    # Fail fast if no packages found
    if [[ ${pkg_count} -eq 0 ]]; then
        error "ERROR: RPM package list is empty for ${root_fs_dir}"
        return 1
    fi

    return 0
}

# For RPM/DNF mode, RPM handles dependencies automatically
# Only need implicit packages in PORTAGE mode
image_packages_implicit() {
    return 0
}

get_metadata() {
    local prefix="$1"
    local pkg="$2"
    local key="$3"

    # Try RPM first if RPM database exists and package looks like RPM format
    local rpm_val=$(rpm_get_metadata "${prefix}" "${pkg}" "${key}" 2>/dev/null)
    if [[ -n "$rpm_val" ]]; then
        echo "$rpm_val"
        return 0
    fi

    # We should not be handling non-RPM packages here
    exit 1
}

start_image_rpm() {
  local root_fs_dir="$1"

    rpm_install_init "${root_fs_dir}"

    # Install filesystem RPM to provide basic directory structure
    # This replaces baselayout and creates /usr/lib, /etc, /bin -> usr/bin symlinks, etc.
    rpm_install_package "${root_fs_dir}" filesystem || {
        error "Failed to install filesystem package"
        return 1
    }

    # Install azurelinux-repos and azurelinux-repos-cloud-native to get the official
    # repository definitions and GPG keys shipped by Azure Linux.
    rpm_install_package "${root_fs_dir}" azurelinux-repos azurelinux-repos-cloud-native azurelinux-release || {
        error "Failed to install azurelinux-repos packages"
        return 1
    }

    # Remove the bootstrap repo now that the package-provided repos are in place.
    rpm_use_official_repos "${root_fs_dir}"

    # Create sysusers.d configs and run systemd-sysusers to create users/groups
    # BEFORE any RPM packages are installed, since RPM %pre scriptlets may need them
    start_image_uids_rpm "${root_fs_dir}"

    # Download bootloader packages while /etc/yum.repos.d is still available
    download_bootloader_packages_rpm "${root_fs_dir}"
}

finish_image_rpm() {
  local root_fs_dir="$1"

    # Create /usr/share/oem -> ../../oem symlink for backward compatibility
    # The OEM partition is mounted at /oem, but legacy configs reference /usr/share/oem
    # Use relative symlink (../../oem) so it works correctly when accessed via /sysroot in initrd
    # See: https://github.com/flatcar/bootengine/pull/58
    sudo mkdir -p "${root_fs_dir}/usr/share"
    sudo ln -sfT ../../oem "${root_fs_dir}/usr/share/oem"

    # Preserve compatibility with agents that probe the Ubuntu CA anchor path.
    # /usr is read-only at runtime, so kubelet cannot create this via hostPath
    # DirectoryOrCreate after boot.
    sudo install -d -m 0755 "${root_fs_dir}/usr/local/share/ca-certificates"

    # Remove legacy coreos compat symlinks — ACL uses /usr/share/distro,
    # not /usr/share/flatcar, so these would be dead.
    sudo rm -f "${root_fs_dir}/usr/share/coreos"
    sudo rm -f "${root_fs_dir}/etc/coreos"

    # In RPM mode, the kernel is installed by Azure Linux RPM to /boot/vmlinuz-*.
    # Find and move it to the expected location for grub.cfg
    local kernel_file
    local -a _kernel_files=()
    local _kf
    for _kf in "${root_fs_dir}"/boot/vmlinuz-*; do
        [[ -f "${_kf}" && "${_kf}" != *.hmac ]] && _kernel_files+=("${_kf}")
    done
    if [[ ${#_kernel_files[@]} -gt 1 ]]; then
        die "RPM mode: Expected exactly 1 kernel in /boot, found ${#_kernel_files[@]}: ${_kernel_files[*]}"
    fi
    kernel_file="${_kernel_files[0]:-}"
    if [[ -n "${kernel_file}" ]]; then
      BOOT_FC_PATH="${root_fs_dir}/boot/flatcar"

      # Extract kernel version from filename (e.g., vmlinuz-6.6.112.1-2.azl3 -> 6.6.112.1-2.azl3)
      local kernel_version
      kernel_version=$(basename "${kernel_file}" | sed 's/vmlinuz-//')
      info "RPM mode: Kernel version is ${kernel_version}"

      generate_initramfs_dracut "${root_fs_dir}" "${kernel_version}" "${BOOT_FC_PATH}"

      # The kernel RPM creates a symlink /usr/lib/modules/<version>/vmlinuz ->
      # /boot/vmlinuz-<version> In UKI mode, uki_install.sh later removes
      # /boot/vmlinuz-* from the ESP (the kernel is embedded in the UKI),
      # leaving a dead symlink that fails the cl.filesystem/deadlinks test.
      # Remove it now while the rootfs is still mounted.
      if [[ "${BOOTLOADER_MODE}" == "uki" ]]; then
          local modules_vmlinuz="${root_fs_dir}/usr/lib/modules/${kernel_version}/vmlinuz"
          if [[ -L "${modules_vmlinuz}" ]]; then
              # UKI embeds the kernel, so /boot/vmlinuz-* will be removed from
              # the ESP later by uki_install.sh.  Replace the dangling symlink
              # with a real copy of the kernel so that kdumpctl/kexec can still
              # find it at /usr/lib/modules/<version>/vmlinuz.
              info "RPM mode: Replacing kernel symlink with real copy for kdump (UKI mode)"
              sudo rm -f "${modules_vmlinuz}"
              sudo cp "${kernel_file}" "${modules_vmlinuz}"
          fi

          # Copy it to /usr/lib/modules/<version>/config (on the rootfs) so
          # tools like kubeadm can still find the kernel config at runtime.
          local boot_config="${root_fs_dir}/boot/config-${kernel_version}"
          local modules_config="${root_fs_dir}/usr/lib/modules/${kernel_version}/config"
          if [[ -f "${boot_config}" ]]; then
              info "RPM mode: Copying kernel config to ${modules_config}"
              sudo cp "${boot_config}" "${modules_config}"
          fi
      else
          # Grub mode: move the kernel to its final location (no copy needed
          # at the original path since grub references vmlinuz-a directly).
          LINUX_KERNEL_DIR_A="${BOOT_FC_PATH}/vmlinuz-a"
          info "RPM mode: Moving kernel from ${kernel_file} to ${LINUX_KERNEL_DIR_A}"
          sudo mv "${kernel_file}" "${LINUX_KERNEL_DIR_A}"

          # The kernel RPM symlink /usr/lib/modules/<version>/vmlinuz now
          # points to the old /boot/vmlinuz-* path which no longer exists.
          # Replace it with a real copy so kdump/kexec can still find it.
          local modules_vmlinuz="${root_fs_dir}/usr/lib/modules/${kernel_version}/vmlinuz"
          if [[ -L "${modules_vmlinuz}" ]]; then
              info "RPM mode: Replacing dangling kernel symlink for kdump (grub mode)"
              sudo rm -f "${modules_vmlinuz}"
              sudo cp "${LINUX_KERNEL_DIR_A}" "${modules_vmlinuz}"
          fi
      fi
    else
      die "RPM mode: No kernel found in ${root_fs_dir}/boot/"
    fi

    # Generate an fstab for Image Customizer (IC) partition discovery.
    # IC scans image partitions for an fstab to discover the partition layout.
    #
    # This file is placed at /usr/share/ic/etc/fstab on USR-A, deliberately
    # outside the /etc overlay lowerdir (/usr/share/distro/etc/). This means:
    #   - systemd-fstab-generator never sees it, so no .mount unit conflicts
    #     with existing static units (e.g. oem.mount).
    #   - There is no /etc/fstab visible at runtime (matching Flatcar behavior).
    #   - IC searches for this path during offline partition discovery.
    #
    # /usr uses /dev/mapper/usr so that IC's verity detection recognizes it as a
    # dm-verity device.
    info "RPM mode: Generating /usr/share/ic/etc/fstab for Image Customizer"
    sudo mkdir -p "${root_fs_dir}/usr/share/ic/etc"
    sudo tee "${root_fs_dir}/usr/share/ic/etc/fstab" > /dev/null <<'FSTAB'
# ACL partition table — consumed by Image Customizer for offline customization.
# This file is NOT visible at runtime (/etc/fstab does not exist).
# It lives at /usr/share/ic/etc/fstab on the USR-A partition.
/dev/mapper/usr                                /usr   btrfs  ro,compress=zstd   0  0
LABEL=ROOT                                     /      ext4   rw                 0  1
LABEL=EFI-SYSTEM                               /boot  vfat   rw                 0  2
LABEL=OEM                                      /oem   btrfs  rw,compress=zlib   0  0
FSTAB
}

# Create sysusers.d configs for all system users/groups needed by ACL
# Called early from start_image_rpm() so users exist before RPM %pre scriptlets run
start_image_uids_rpm() {
  local root_fs_dir="$1"

    # RPM mode: Create sysusers.d configs for system users that Azure Linux expects
    # but doesn't provide via sysusers.d (normally created by RPM scriptlets)
    info "RPM mode: Creating sysusers.d configs for essential system users"
    sudo mkdir -p "${root_fs_dir}/usr/lib/sysusers.d"

    # D-Bus messagebus user - required for dbus.service
    sudo tee "${root_fs_dir}/usr/lib/sysusers.d/dbus.conf" > /dev/null <<'SYSUSERS_DBUS'
# D-Bus system message bus user
u messagebus 81 "System Message Bus" /run/dbus
SYSUSERS_DBUS

    # polkitd user - Fedora setup uses UID 114
    sudo tee "${root_fs_dir}/usr/lib/sysusers.d/polkit.conf" > /dev/null <<'SYSUSERS_POLKIT'
# PolicyKit daemon user
g polkitd 114 -
u polkitd 114:114 "PolicyKit Daemon Owner" /etc/polkit-1 /bin/false
SYSUSERS_POLKIT

    # tss user/group - Azure Linux tpm2-tss uses UID/GID 59 (matches Gentoo)
    sudo tee "${root_fs_dir}/usr/lib/sysusers.d/tss.conf" > /dev/null <<'SYSUSERS_TSS'
# TCG Software Stack (TPM2) user
g tss 59 -
u tss 59:59 "TCG Software Stack" /var/lib/tpm /bin/false
SYSUSERS_TSS

    # sshd user - required for OpenSSH privilege separation
    # Alas, 74 which is used by Fedora, is already taken in 3.0 filesystem package, so for now we will dynamically allocate
    sudo tee "${root_fs_dir}/usr/lib/sysusers.d/sshd.conf" > /dev/null <<'SYSUSERS_SSHD'
# SSH privilege separation user
g sshd - -
u sshd - "Privilege-separated SSH" /usr/share/empty.sshd
SYSUSERS_SSHD

    # systemd-coredump user - for coredump handling
    sudo tee "${root_fs_dir}/usr/lib/sysusers.d/systemd-coredump.conf" > /dev/null <<'SYSUSERS_COREDUMP'
# systemd coredump user
u systemd-coredump - "systemd Core Dumper" /
SYSUSERS_COREDUMP

    # systemd-network user - for networkd
    sudo tee "${root_fs_dir}/usr/lib/sysusers.d/systemd-network.conf" > /dev/null <<'SYSUSERS_NETWORK'
# systemd network management user
u systemd-network - "systemd Network Management" /
SYSUSERS_NETWORK

    # systemd-resolve user - for resolved
    sudo tee "${root_fs_dir}/usr/lib/sysusers.d/systemd-resolve.conf" > /dev/null <<'SYSUSERS_RESOLVE'
# systemd DNS resolver user
u systemd-resolve - "systemd Resolver" /
SYSUSERS_RESOLVE

    # systemd-timesync user - for timesyncd
    sudo tee "${root_fs_dir}/usr/lib/sysusers.d/systemd-timesync.conf" > /dev/null <<'SYSUSERS_TIMESYNC'
# systemd time synchronization user
u systemd-timesync - "systemd Time Synchronization" /
SYSUSERS_TIMESYNC

    # chrony user - for chrony, required for oem-azure sysext
    sudo tee "${root_fs_dir}/usr/lib/sysusers.d/chrony.conf" > /dev/null <<'SYSUSERS_CHRONY'
# chrony time daemon user
g chrony - -
u chrony - "chrony time daemon" /var/lib/chrony /sbin/nologin
SYSUSERS_CHRONY

    # docker group - for docker socket permissions
    sudo tee "${root_fs_dir}/usr/lib/sysusers.d/docker.conf" > /dev/null <<'SYSUSERS_DOCKER'
# Docker group for socket access
g docker - -
SYSUSERS_DOCKER

    # systemd-journal group - for reading journal logs (GID 190 from Flatcar)
    # core user needs to be a member for journalctl access
    sudo tee "${root_fs_dir}/usr/lib/sysusers.d/systemd-journal.conf" > /dev/null <<'SYSUSERS_JOURNAL'
# systemd journal group - allows reading system logs
g systemd-journal 190 -
SYSUSERS_JOURNAL

    # wheel and sudo groups - for administrative access
    sudo tee "${root_fs_dir}/usr/lib/sysusers.d/admin-groups.conf" > /dev/null <<'SYSUSERS_ADMIN'
# Administrative groups
g wheel 10 -
g sudo 150 -
SYSUSERS_ADMIN

    # core user - retained for Flatcar/ACL compatibility (UID/GID 500)
    # Phase 2: core is fully inert — /sbin/nologin shell, no wheel, no docker.
    # The user exists only as an identity for file ownership.
    # All interactive access goes through the Azure-provisioned admin user.
    sudo tee "${root_fs_dir}/usr/lib/sysusers.d/core.conf" > /dev/null <<'SYSUSERS_CORE'
# Core user - inert identity for file ownership
g core 500 -
u core 500:500 "Inert Identity" /home/core /sbin/nologin
SYSUSERS_CORE

    # Run systemd-sysusers to create users in /etc/passwd and /etc/group
    info "RPM mode: Running systemd-sysusers to create users"
    sudo systemd-sysusers --root="${root_fs_dir}"

    info "RPM mode: Created sysusers.d configs for system users"
}

# Download grub/shim/systemd-boot packages for later use by grub_install.sh and uki_install.sh
# Must be called while /etc/yum.repos.d is still available in the root_fs_dir
download_bootloader_packages_rpm() {
    local root_fs_dir="$1"

    info "RPM mode: Pre-downloading bootloader packages (grub2, shim, systemd-boot)"
    rpm_staging=$(rpm_get_staging_dir)
    rpm_download_packages "${rpm_staging}" "${root_fs_dir}" grub2 grub2-efi grub2-efi-binary shim systemd-boot
}

finish_image_cleanup_issue_rpm() {
    local root_fs_dir="$1"

    # Remove package-provided /etc/issue files and conflicting tmpfiles.d entries.
    # Azure Linux packages install /etc/issue and tmpfiles.d rules that would
    # interfere with systemd-tmpfiles --create. The CIS hardening function
    # (_configure_cis_hardening_rpm) later writes the final CIS banner and
    # removes issuegen entirely.
    info "RPM mode: Cleaning up package-provided /etc/issue conflicts"

    # Remove physical files
    sudo rm -f "${root_fs_dir}/etc/issue" "${root_fs_dir}/etc/issue.net"
    sudo rm -f "${root_fs_dir}/usr/lib/issue" "${root_fs_dir}/usr/lib/issue.net"
    sudo rm -f "${root_fs_dir}/usr/share/factory/etc/issue" "${root_fs_dir}/usr/share/factory/etc/issue.net"

    # Remove conflicting tmpfiles.d entries
    # etc.conf has: C! /etc/issue - - - -
    # provision.conf has: f^ /etc/issue.d/50-provision.conf - - - - login.issue
    if [[ -f "${root_fs_dir}/usr/lib/tmpfiles.d/etc.conf" ]]; then
        sudo sed -i '/\/etc\/issue[^.].*$/d' "${root_fs_dir}/usr/lib/tmpfiles.d/etc.conf"
    fi
    if [[ -f "${root_fs_dir}/usr/lib/tmpfiles.d/provision.conf" ]]; then
        sudo sed -i '/\/etc\/issue\.d/d' "${root_fs_dir}/usr/lib/tmpfiles.d/provision.conf"
    fi
}

finish_image_kernel_config_rpm() {
    local root_fs_dir="$1"

    # In RPM mode, kernel config is at /boot/config-* (Azure Linux layout)
    local config_file
    config_file=$(ls "${root_fs_dir}"/boot/config-* 2>/dev/null | head -1)
    if [[ -n "${config_file}" ]]; then
        cp "${config_file}" "${BUILD_DIR}/${image_kconfig}"
    else
        die "RPM mode: No kernel config found in /boot/"
    fi
}

finish_image_selinux_rpm() {
    local root_fs_dir="$1"

    # Use the targeted policy file_contexts to label the filesystem
    local file_contexts="${root_fs_dir}/etc/selinux/targeted/contexts/files/file_contexts"
    info "RPM mode: Labeling filesystem with targeted SELinux policy"
    #sudo setfiles -Dv -r "${root_fs_dir}" "${file_contexts}" "${root_fs_dir}" >/dev/null
    sudo setfiles -Dv -r "${root_fs_dir}" "${file_contexts}" "${root_fs_dir}/etc" >/dev/null
    #sudo setfiles -Dv -r "${root_fs_dir}" "${file_contexts}" "${root_fs_dir}/usr" >/dev/null
}

# ── Machine-id: remove for first-boot detection ──────────────────────────────
_remove_machine_id_rpm() {
    local root_fs_dir="$1"

    # Remove /etc/machine-id so that the later bulk-copy of /etc to the
    # overlay lowerdir naturally excludes it.  Without machine-id in the
    # lowerdir, systemd sees a missing file after overlay mount and triggers
    # first-boot logic (ConditionFirstBoot=yes, systemd-firstboot, etc.).
    # Nothing between here and the cp -a recreates the file.
    info "RPM mode: Removing /etc/machine-id for first-boot detection"
    sudo rm -f "${root_fs_dir}/etc/machine-id"
}

# ── SSH: config, authorized_keys, socket activation ──────────────────────────
_configure_ssh_rpm() {
    local root_fs_dir="$1"

    # sshd privilege separation directory
    sudo tee "${root_fs_dir}/usr/lib/tmpfiles.d/sshd.conf" > /dev/null <<'TMPFILES_SSHD'
# SSH privilege separation directory
d /var/lib/sshd 0755 root root - -
TMPFILES_SSHD

    # Configure sshd to look for authorized_keys in the ignition location
    # Ignition places SSH keys in ~/.ssh/authorized_keys.d/ignition
    info "RPM mode: Configuring sshd AuthorizedKeysFile for Ignition"
    local ssh_config_dir="${root_fs_dir}/etc/ssh"
    sudo mkdir -p "${ssh_config_dir}/sshd_config.d"
    sudo tee "${ssh_config_dir}/sshd_config.d/10-authorized-keys.conf" > /dev/null <<'SSHD_CONF'
# Support both traditional authorized_keys and Ignition's authorized_keys.d/ignition
AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys.d/ignition
SSHD_CONF
    sudo chmod 644 "${ssh_config_dir}/sshd_config.d/10-authorized-keys.conf"

    # Phase 1 hardening: disable SSH password authentication at build time.
    # Closes the window between boot and WALinuxAgent provisioning where
    # PasswordAuthentication defaults to 'yes'. Key-based login is unaffected.
    # Also disable KbdInteractiveAuthentication and ChallengeResponseAuthentication
    # to prevent password-based logins via keyboard-interactive/PAM.
    # Consistent with Flatcar's 80-flatcar-walinuxagent.conf behaviour.
    info "RPM mode: Disabling SSH password authentication"
    sudo tee "${ssh_config_dir}/sshd_config.d/50-acl-no-password-auth.conf" > /dev/null <<'SSHD_NOPASSWD'
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
SSHD_NOPASSWD
    sudo chmod 644 "${ssh_config_dir}/sshd_config.d/50-acl-no-password-auth.conf"

    # Ensure sshd_config includes the .d directory
    local sshd_config="${ssh_config_dir}/sshd_config"
    if [[ ! -f "${sshd_config}" ]]; then
        # sshd_config doesn't exist - create a minimal one with Include
        info "RPM mode: Creating sshd_config with Include directive"
        sudo tee "${sshd_config}" > /dev/null <<'SSHD_CONFIG_EOF'
# Include drop-in configurations
Include /etc/ssh/sshd_config.d/*.conf
SSHD_CONFIG_EOF
        sudo chmod 644 "${sshd_config}"
    elif ! sudo grep -q "^Include.*/etc/ssh/sshd_config.d" "${sshd_config}"; then
        info "RPM mode: Adding Include directive to existing sshd_config"
        sudo sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' "${sshd_config}"
    else
        info "RPM mode: sshd_config already has Include directive"
    fi

    # Switch sshd to socket activation (matching Flatcar behavior)
    # The Azure Linux openssh RPM only ships sshd.service (traditional daemon).
    # Socket activation means systemd listens on port 22 and spawns sshd per-connection,
    # which is more efficient and matches what Flatcar's cl.network.listeners test expects.
    info "RPM mode: Setting up sshd socket activation"
    # Create sshd.socket - systemd will listen on port 22
    sudo tee "${root_fs_dir}/usr/lib/systemd/system/sshd.socket" > /dev/null <<'SSHD_SOCKET'
[Unit]
Description=OpenSSH Server Socket
Conflicts=sshd.service

[Socket]
ListenStream=22
Accept=yes

[Install]
WantedBy=sockets.target
SSHD_SOCKET
    # Create sshd@.service - per-connection sshd instance (template)
    sudo tee "${root_fs_dir}/usr/lib/systemd/system/sshd@.service" > /dev/null <<'SSHD_AT_SERVICE'
[Unit]
Description=OpenSSH per-connection server daemon

[Service]
ExecStart=-/usr/sbin/sshd -i -e
StandardInput=socket
StandardError=journal
SSHD_AT_SERVICE
    # Add drop-in to ensure host keys are generated before accepting connections
    sudo mkdir -p "${root_fs_dir}/usr/lib/systemd/system/sshd@.service.d"
    sudo tee "${root_fs_dir}/usr/lib/systemd/system/sshd@.service.d/sshd-keygen.conf" > /dev/null <<'SSHD_KEYGEN_DROPIN'
[Unit]
Wants=sshd-keygen.service
After=sshd-keygen.service
SSHD_KEYGEN_DROPIN
    # Disable sshd.service (enabled by 90-default.preset) and enable sshd.socket instead
    printf "disable sshd.service\nenable sshd.socket\n" | \
    sudo tee "${root_fs_dir}/usr/lib/systemd/system-preset/50-acl-sshd.preset" > /dev/null
    # Remove any existing sshd.service enable symlinks from the RPM
    sudo rm -f "${root_fs_dir}/etc/systemd/system/multi-user.target.wants/sshd.service"
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/multi-user.target.wants/sshd.service"
}

# ── Sudo: Flatcar-compatible sudoers policy ──────────────────────────────────
_configure_sudo_rpm() {
    local root_fs_dir="$1"

    # Configure sudo policy for ACL:
    # - sudo group gets NOPASSWD (used by kola tests via Ignition)
    # - Phase 2: core has NO sudoers entry (inert user, cannot sudo)
    # - LESSCHARSET preserved for systemd commands that call less
    info "RPM mode: Configuring sudoers drop-in"
    sudo mkdir -p "${root_fs_dir}/etc/sudoers.d"
    sudo tee "${root_fs_dir}/etc/sudoers.d/flatcar-compat" > /dev/null <<'SUDOERS_EOF'
## ACL sudo policy

## Pass LESSCHARSET through for systemd commands run through sudo that call less.
Defaults env_keep += "LESSCHARSET"

## Reset umask to 022 on sudo — prevents the user's CIS-mandated umask 027
## from leaking into root processes, which would make root-created files
## unreadable by non-root (e.g., coreos-cloudinit drop-ins in /run).
Defaults umask_override, umask=0022

## enable passwordless access for sudo group
%sudo ALL=(ALL) NOPASSWD: ALL
SUDOERS_EOF
    sudo chmod 440 "${root_fs_dir}/etc/sudoers.d/flatcar-compat"
}

# ── NTP / NFS / RPC service fixes ────────────────────────────────────────────
_fix_ntp_nfs_services_rpm() {
    local root_fs_dir="$1"

    # Add drop-in for ntpdate.service to ensure DNS is ready before running
    # The service has After=nss-lookup.target but DNS servers may not be configured yet
    # We add retries to handle the race between DHCP configuring DNS and ntpdate running
    if [[ -f "${root_fs_dir}/usr/lib/systemd/system/ntpdate.service" ]]; then
        info "RPM mode: Adding ntpdate.service drop-in for DNS retry handling and timesyncd conflict"
        sudo mkdir -p "${root_fs_dir}/usr/lib/systemd/system/ntpdate.service.d"
        cat <<'EOF' | sudo tee "${root_fs_dir}/usr/lib/systemd/system/ntpdate.service.d/10-flatcar.conf" > /dev/null
[Unit]
# Ensure DNS resolution is available before trying to resolve NTP server names
After=systemd-resolved.service
Wants=systemd-resolved.service
# Conflict with systemd-timesyncd - only one NTP client should run
Conflicts=systemd-timesyncd.service

[Service]
# Retry on failure - DNS may not be configured immediately after resolved starts
# DHCP needs time to provide DNS servers to systemd-resolved
Restart=on-failure
RestartSec=5
StartLimitInterval=60
StartLimitBurst=5
EOF
    fi

    # Re-enable systemd-timesyncd.service via direct symlink.
    # azurelinux-release's 90-default.preset explicitly disables systemd-timesyncd,
    # but the linux.ntp and acl.basic/ServicesActive tests expect timesyncd to be active.
    info "RPM mode: Re-enabling systemd-timesyncd.service"
    sudo mkdir -p "${root_fs_dir}/usr/lib/systemd/system/sysinit.target.wants"
    sudo ln -sf ../systemd-timesyncd.service "${root_fs_dir}/usr/lib/systemd/system/sysinit.target.wants/systemd-timesyncd.service"

    # TODO: reevaluate the approach for nfs-mountd ordering
    # Add drop-in for nfs-mountd.service to ensure rpcbind is ready before starting
    # Without this ordering, rpc.mountd blocks trying to register with portmapper,
    # exceeds the 45s TimeoutStartSec, and gets killed - failing nfs-server.service too
    if [[ -f "${root_fs_dir}/usr/lib/systemd/system/nfs-mountd.service" ]]; then
        info "RPM mode: Adding nfs-mountd.service drop-in for rpcbind dependency"
        sudo mkdir -p "${root_fs_dir}/usr/lib/systemd/system/nfs-mountd.service.d"
        cat <<'EOF' | sudo tee "${root_fs_dir}/usr/lib/systemd/system/nfs-mountd.service.d/10-rpcbind-dependency.conf" > /dev/null
[Unit]
# rpc.mountd needs rpcbind to register its RPC program number.
# Ordering after rpcbind.service (not just .socket) avoids a 60-second
# libtirpc timeout caused by socket-activation handoff races: mountd's
# first RPC registration call can stall when rpcbind.service hasn't
# finished starting yet, exceeding the 45s TimeoutStartSec.
Wants=rpcbind.service
After=rpcbind.service
EOF
    fi

    # Fix rpc-statd.service - the Azure Linux unit uses Type=forking with a legacy
    # PIDFile=/var/run/rpc.statd.pid path.  Switch to foreground mode and fix the path.
    if [[ -f "${root_fs_dir}/usr/lib/systemd/system/rpc-statd.service" ]]; then
        info "RPM mode: Fixing rpc-statd.service (foreground mode + /var/run → /run)"
        sudo sed -i 's|/var/run/|/run/|g' "${root_fs_dir}/usr/lib/systemd/system/rpc-statd.service"
        sudo mkdir -p "${root_fs_dir}/usr/lib/systemd/system/rpc-statd.service.d"
        cat <<'EOF' | sudo tee "${root_fs_dir}/usr/lib/systemd/system/rpc-statd.service.d/10-foreground.conf" > /dev/null
[Service]
Type=simple
ExecStart=
ExecStart=/usr/sbin/rpc.statd --no-notify -F
PIDFile=
EOF
    fi

    # Fix rpcbind.socket - uses legacy /var/run/ path
    if [[ -f "${root_fs_dir}/usr/lib/systemd/system/rpcbind.socket" ]]; then
        info "RPM mode: Fixing rpcbind.socket (/var/run → /run)"
        sudo sed -i 's|/var/run/|/run/|g' "${root_fs_dir}/usr/lib/systemd/system/rpcbind.socket"
    fi

    # Create /var/lib/nfs directories needed by rpc-statd and NFS server via tmpfiles
    # The nfs-utils RPM only creates v4recovery; sm and sm.bak are missing from the package
    # /var is stateful so we use tmpfiles.d to create these at boot, not mkdir at build time
    info "RPM mode: Adding tmpfiles.d config for NFS state directories"
    cat <<'EOF' | sudo tee "${root_fs_dir}/usr/lib/tmpfiles.d/nfs-utils.conf" > /dev/null
# NFS state directories required by rpc-statd and NFS server
d /var/lib/nfs 0755 root root -
d /var/lib/nfs/sm 0755 root root -
d /var/lib/nfs/sm.bak 0755 root root -
d /var/lib/nfs/v4recovery 0755 root root -
d /var/lib/nfs/v4root 0755 root root -
d /var/lib/nfs/rpc_pipefs 0755 root root -
EOF
}

# ── Generate hwdb.bin in /usr/lib/udev during image build ───────────────────────────────
_generate_hwdb_rpm() {
    local root_fs_dir="$1"

    # Generating hwdb.bin in /usr/lib/udev during image build.
    # During image build, post install scripts in systemd-udevd package generates
    # /etc/udev/hwdb.bin.
    # When systemd detects that /etc needs to be updated for ex during first boot, systemd-hwdb-update
    # service runs and regenerates this binary hardware db in /etc/udev itself.
    # Regenerating this file during image build, we are
    # - making the hwdb db immutable, since it lies in /usr
    # - avoids situations when systemd-hwdb-update service can fail due to low space on medium backing
    #   the writeable /etc upper dir in overlayfs (for ex service runs before systemd has performed the resize)
    if [ -d "${root_fs_dir}/usr/lib/udev/hwdb.d" ]; then
        info "RPM mode: generating hwdb.bin in /usr"
        if [ -f "${root_fs_dir}/usr/bin/systemd-hwdb" ]; then
            info "RPM mode: /usr/bin/systemd-hwdb is present, running update"
            local -a build_args
            if [[ "${BOARD}" == "arm64-usr" ]]; then
                build_args+=(QEMU_LD_PREFIX="${root_fs_dir}")
            else
                build_args+=("${root_fs_dir}/usr/lib/ld-linux-x86-64.so.2" \
                                "--library-path" "${root_fs_dir}/usr/lib/systemd:${root_fs_dir}/usr/lib")
            fi
            if sudo "${build_args[@]}" "${root_fs_dir}/usr/bin/systemd-hwdb" --usr --root="${root_fs_dir}" update; then
                if [ -f "${root_fs_dir}/etc/udev/hwdb.bin" ]; then
                    info "RPM mode: removing /etc/udev/hwdb.bin"
                    sudo rm -f "${root_fs_dir}/etc/udev/hwdb.bin"
                fi
            else
                error "RPM mode: Failed to generate hwdb.bin in /usr"
            fi
        fi
    fi
}

# ── Mask afterburn SSH-key injection for inert core user ─────────────────────
_mask_core_sshkeys_rpm() {
    local root_fs_dir="$1"

    # Phase 3: coreos-metadata-sshkeys@core.service writes SSH public keys
    # from Azure IMDS into ~core/.ssh/authorized_keys. With core fully inert
    # (/sbin/nologin, no sudoers), injecting keys is pointless and leaves a
    # stale authorized_keys file. The admin user's keys are handled by
    # WALinuxAgent. Masking (symlink to /dev/null) takes precedence over
    # the DefaultInstance=core enable symlink created by %systemd_post.
    info "RPM mode: Masking coreos-metadata-sshkeys@core.service (Phase 3)"
    sudo ln -sfT /dev/null "${root_fs_dir}/etc/systemd/system/coreos-metadata-sshkeys@core.service"
}

# ── Remove Flatcar components not used by ACL ────────────────────────────────
_remove_unused_flatcar_components_rpm() {
    local root_fs_dir="$1"

    # Remove extend-filesystems - uses cgpt (not available in Azure Linux) and
    # the coreos-resize GPT partition type which ACL does not use
    info "RPM mode: Removing extend-filesystems (requires cgpt, not available)"
    sudo rm -f "${root_fs_dir}/usr/lib/flatcar/extend-filesystems"
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/extend-filesystems.service"
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/multi-user.target.wants/extend-filesystems.service"

    # Remove flatcar-update/flatcar-install - ACL uses a different update mechanism
    info "RPM mode: Removing flatcar-update, flatcar-install, and flatcar-reset (not used by ACL)"
    sudo rm -f "${root_fs_dir}/usr/lib/tmpfiles.d/flatcar-update.conf"
    sudo rm -f "${root_fs_dir}/usr/bin/flatcar-update"
    sudo rm -f "${root_fs_dir}/usr/bin/flatcar-install"
    sudo rm -f "${root_fs_dir}/usr/bin/coreos-install"
    sudo rm -f "${root_fs_dir}/etc/flatcar/update.conf"
    # removing flatcar-reset for GA, let's revisit whether we want to support this on ACL
    sudo rm -f "${root_fs_dir}/usr/bin/flatcar-reset"

    # Remove motdgen - watches /etc/flatcar/update.conf
    info "RPM mode: Removing motdgen (depends on flatcar update.conf)"
    sudo rm -f "${root_fs_dir}/usr/lib/flatcar/motdgen"
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/motdgen.path"
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/motdgen.service"
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/multi-user.target.wants/motdgen.path"
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/multi-user.target.wants/motdgen.service"

    # Note: /etc/issue cleanup was moved to finish_image_rpm() to run before systemd-tmpfiles --create

    # Remove flatcar-setup-environment.service - requires /oem/bin/flatcar-setup-environment
    # which is an OEM-specific script that ACL does not provide. Also strip references
    # from any dependent units (system-config.target, user-cloudinit, user-config*, etc.)
    info "RPM mode: Removing flatcar-setup-environment.service (no OEM script)"
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/flatcar-setup-environment.service"
    # Strip Requires= and After= references from units that depend on it
    for unit_file in \
        "${root_fs_dir}/usr/lib/systemd/system/system-config.target" \
        "${root_fs_dir}/usr/lib/systemd/system/user-cloudinit@.service" \
        "${root_fs_dir}/usr/lib/systemd/system/user-cloudinit-proc-cmdline.service" \
        "${root_fs_dir}/usr/lib/systemd/system/user-configdrive.service" \
        "${root_fs_dir}/usr/lib/systemd/system/user-configvirtfs.service" \
        "${root_fs_dir}/usr/lib/systemd/system/user-config-ovfenv.service"; do
        if [[ -f "${unit_file}" ]]; then
            sudo sed -i '/flatcar-setup-environment\.service/d' "${unit_file}"
        fi
    done
}

# ── Disk auto-grow: systemd-repart + growfs ──────────────────────────────────
_configure_disk_autogrow_rpm() {
    local root_fs_dir="$1"

    # Enable systemd-repart + systemd-growfs for rootfs auto-grow
    # The ROOT partition uses the DPS (Discoverable Partitions Spec) root type GUID,
    # resolved at build time by disk_util from the "dps-root" placeholder in disk_layout.json
    # (x86-64: 4F68BCE3-..., aarch64: B921B045-...).
    # systemd-repart grows the partition to fill available disk space,
    # then systemd-growfs-root grows the ext4 filesystem to match.
    info "RPM mode: Enabling systemd-repart and systemd-growfs for rootfs auto-grow"

    # Create repart.d config to grow the ROOT partition
    sudo mkdir -p "${root_fs_dir}/usr/lib/repart.d"
    sudo tee "${root_fs_dir}/usr/lib/repart.d/10-root.conf" > /dev/null <<'REPART_EOF'
[Partition]
Type=root
Label=ROOT
GrowFileSystem=no
REPART_EOF

    # Enable systemd-repart.service (grows partition at boot)
    sudo mkdir -p "${root_fs_dir}/usr/lib/systemd/system/sysinit.target.wants"
    sudo ln -sf ../systemd-repart.service "${root_fs_dir}/usr/lib/systemd/system/sysinit.target.wants/systemd-repart.service"

    # Drop-in for systemd-repart.service: make partition growth best-effort.
    # Use "-" prefix on ExecStart so any failure is non-fatal.  This handles:
    #   - RAID/LVM roots where repart can't resolve / to a single GPT disk (exit 76)
    #   - No GPT partition table found (exit 77)
    #   - Not enough free space to grow the partition (exit 1, e.g. RAID0 tests)
    # Root partition growth is opportunistic — if there's space, grow; if not, boot anyway.
    sudo mkdir -p "${root_fs_dir}/usr/lib/systemd/system/systemd-repart.service.d"
    cat <<'EOF' | sudo tee "${root_fs_dir}/usr/lib/systemd/system/systemd-repart.service.d/10-best-effort.conf" > /dev/null
[Service]
ExecStart=
ExecStart=-/usr/bin/systemd-repart --dry-run=no
EOF

    # Enable systemd-growfs-root.service (grows filesystem after partition resize)
    sudo ln -sf ../systemd-growfs-root.service "${root_fs_dir}/usr/lib/systemd/system/sysinit.target.wants/systemd-growfs-root.service"
}

# ── Remove systemd components not built by Flatcar ──────────────────────────
_remove_unused_systemd_components_rpm() {
    local root_fs_dir="$1"

    # Remove systemd-homed — Flatcar does not build these (USE flag "homed" is
    # off). Remove the service units, daemons, CLI tool, and PAM module shipped
    # by the Azure Linux systemd-udev RPM to stay in parity.
    info "RPM mode: Removing systemd-homed (not built by Flatcar)"
    # /usr/lib64 -> lib, so only /usr/lib paths are needed.
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/systemd-homed.service"
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/systemd-homed-activate.service"
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/systemd-homed"
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/systemd-homework"
    sudo rm -f "${root_fs_dir}/usr/bin/homectl"
    sudo rm -f "${root_fs_dir}/usr/lib/security/pam_systemd_home.so"
    
    # Also clean up /etc symlinks left by RPM presets — dangling links here
    # cause "Link has been severed" and abort the entire preset population,
    # which prevents sshd.socket (and others) from being enabled at first boot.
    sudo rm -f "${root_fs_dir}/etc/systemd/system/multi-user.target.wants/systemd-homed.service"
    sudo rm -f "${root_fs_dir}/etc/systemd/system/dbus-org.freedesktop.home1.service"
    sudo rm -rf "${root_fs_dir}/etc/systemd/system/systemd-homed.service.wants"

    # Remove systemd-boot-update.service — Flatcar does not build this on the
    # target image (USE flag "boot" is SDK-only). Keep bootctl binary (useful
    # for inspecting the ESP).
    info "RPM mode: Removing systemd-boot-update.service (not built by Flatcar)"
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/systemd-boot-update.service"

    # Removing packet-phone-home.service. This service is NOT needed for ACL images.
    # Reference: https://github.com/flatcar/init/pull/107 Needed for packet/equinix instances.
    # For now, this is the ONLY service which pulls in coreos-metadata.service as dependency,
    # and thus coreos-metadata (default disabled, even via preset) runs in every boot.
    # The packet-phone-home service itself does not run due to unmet conditions (not packet instance/not first boot)
    if [ -f "${root_fs_dir}/usr/lib/systemd/system/packet-phone-home.service" ]; then
        info "RPM mode: Removing packet-phone-home.service (not needed for ACL)"
        sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/packet-phone-home.service"
        for target in "${root_fs_dir}/usr/lib/systemd/system" "${root_fs_dir}/etc/systemd/system"; do
            sudo find "${target}" -type l -name "packet-phone-home.service" -exec rm -f {} \;
        done
    fi
}

# ── PCRlock: Secure Boot condition + arm64 SHA-256 restriction ───────────────
_configure_pcrlock_rpm() {
    local root_fs_dir="$1"

    # Add drop-in for systemd-pcrlock-secureboot-policy.service to skip cleanly
    # when Secure Boot is not available. The upstream unit only gates on
    # ConditionSecurity=measured-uki but lock-secureboot-policy reads the
    # SecureBoot EFI variable and fails with exit-code 1 when it is absent. The
    # drop-in makes this a clean condition skip instead of a hard failure.
    local sb_dropin_dir="${root_fs_dir}/etc/systemd/system/systemd-pcrlock-secureboot-policy.service.d"
    info "RPM mode: Adding Secure Boot condition to pcrlock-secureboot-policy"
    sudo install -d -m 0755 "${sb_dropin_dir}"
    printf '[Unit]\nConditionPathExists=/sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c\n' \
        | sudo tee "${sb_dropin_dir}/condition-secureboot.conf" > /dev/null
    sudo chmod 0644 "${sb_dropin_dir}/condition-secureboot.conf"

    # Restrict pcrlock to SHA-256 only on arm64. Azure's arm64 vTPM allocates
    # only sha256 PCR banks, but the firmware event log still contains sha1 and
    # sha384 digest entries. systemd-pcrlock discovers all three algorithms from
    # the event log, tries to replay them all against the TPM, and fails.
    if [[ "${BOARD}" == "arm64-usr" ]]; then
        local pcrlock_services=(
            systemd-pcrlock-firmware-code.service
            systemd-pcrlock-firmware-config.service
            systemd-pcrlock-make-policy.service
            systemd-pcrlock-secureboot-authority.service
            systemd-pcrlock-secureboot-policy.service
        )
        info "RPM mode: Restricting pcrlock services to SHA-256 algorithm only (arm64)"
        for svc in "${pcrlock_services[@]}"; do
            local dropin_dir="${root_fs_dir}/etc/systemd/system/${svc}.d"
            sudo install -d -m 0755 "${dropin_dir}"
            printf '[Service]\nEnvironment=SYSTEMD_TPM2_HASH_ALGORITHMS=sha256\n' \
                | sudo tee "${dropin_dir}/sha256-only.conf" > /dev/null
            sudo chmod 0644 "${dropin_dir}/sha256-only.conf"
        done
    fi
}

# ── Kdump: enable crash dump collection ──────────────────────────────────────
_configure_kdump_rpm() {
    local root_fs_dir="$1"

    # Enable kdump.service so the crash kernel is armed at boot.
    # The crashkernel=256M kernel cmdline parameter reserves memory
    # (delivered via grub.cfg for GRUB boot and a UKI addon for UKI boot);
    # this preset ensures kexec loads the capture kernel on every boot.
    printf "enable kdump.service\n" | \
    sudo tee "${root_fs_dir}/usr/lib/systemd/system-preset/50-acl-kdump.preset" > /dev/null

    # Add a service drop-in that:
    # 1. Sets DRACUT_NO_XATTR=1 -> dracut-install uses cp --preserve=xattr
    #    which fails when copying files with btrfs.compression xattr to the
    #    ext4 tmpdir.  DRACUT_NO_XATTR=1 skips xattr preservation.
    # 2. Copies the kernel binary to /var/crash/ before kdumpctl starts.
    #    /usr is read-only (dm-verity btrfs), so kdumpctl cannot write the
    #    kdump initramfs there.  KDUMP_BOOTDIR is set to /var/crash (ext4,
    #    writable) via /etc/sysconfig/kdump, so both the kernel and initramfs
    #    live on writable storage.
    info "RPM mode: Adding kdump.service drop-in for DRACUT_NO_XATTR and kernel copy"
    sudo mkdir -p "${root_fs_dir}/usr/lib/systemd/system/kdump.service.d"
    sudo tee "${root_fs_dir}/usr/lib/systemd/system/kdump.service.d/10-acl-kdump.conf" > /dev/null <<'KDUMP_DROPIN'
[Unit]
ConditionKernelCommandLine=crashkernel

[Service]
Environment=DRACUT_NO_XATTR=1
ExecStartPre=/bin/bash -c '/usr/bin/cp -f /usr/lib/modules/$(/usr/bin/uname -r)/vmlinuz /var/crash/vmlinuz-$(/usr/bin/uname -r)'
KDUMP_DROPIN

    # Create /var/crash directory for kdump to write vmcore dumps.
    # On ACL's immutable rootfs, /var is stateful but directories must be
    # created via tmpfiles.d so they persist across boots.
    sudo tee "${root_fs_dir}/usr/lib/tmpfiles.d/kdump.conf" > /dev/null <<'TMPFILES_KDUMP'
# kdump crash dump target directory
d /var/crash 0755 root root -
TMPFILES_KDUMP

    # Ensure /etc/kdump.conf exists with a default config.
    # kdumpctl expects this file to determine the dump target.
    # dracut_args:
    #   --tmpdir /var/crash: use ext4 ROOT for dracut scratch (avoids tmpfs pressure)
    #   -o "setup-root ignition": crash kernel cannot mount dm-verity /usr, so
    #     these modules must be excluded to prevent emergency.target on aarch64
    sudo tee "${root_fs_dir}/etc/kdump.conf" > /dev/null <<'KDUMP_CONF'
# kdump configuration for ACL
# Dump to local filesystem
path /var/crash
core_collector makedumpfile -l --message-level 7 -d 31
dracut_args --tmpdir /var/crash -o "setup-root ignition"
KDUMP_CONF

    # kdumpctl constructs the kernel path as:
    #   ${KDUMP_BOOTDIR}/${KDUMP_IMG}-${kver}
    # and writes the initramfs to the same directory.
    # /usr is read-only (dm-verity btrfs) and /boot is a vfat ESP (too
    # small, no symlink support).  Point KDUMP_BOOTDIR to /var/crash
    # (ext4, writable) where ExecStartPre copies the kernel at boot.
    info "RPM mode: Configuring KDUMP_BOOTDIR/KDUMP_IMG via /etc/sysconfig/kdump"
    sudo mkdir -p "${root_fs_dir}/etc/sysconfig"
    sudo tee "${root_fs_dir}/etc/sysconfig/kdump" > /dev/null <<'KDUMP_SYSCONFIG'
# ACL: /usr is read-only (dm-verity btrfs) and /boot is a vfat ESP
# (too small for initramfs, no symlink support).  Use /var/crash on
# the writable ext4 ROOT partition for both the kernel copy and the
# kdump initramfs.
# The kernel is copied here by the kdump.service ExecStartPre drop-in.
KDUMP_BOOTDIR="/var/crash"
KDUMP_IMG="vmlinuz"
# Crash kernel cmdline: nr_cpus=1 avoids SMP hang on aarch64,
# irqpoll + reset_devices ensure stable device access post-panic.
KDUMP_COMMANDLINE_APPEND="irqpoll nr_cpus=1 reset_devices"
KDUMP_SYSCONFIG
}

# ── Misc: kernel modules, resolv.conf, serial console, etc. ─────────────────
_configure_misc_rpm() {
    local root_fs_dir="$1"

    # Remove umask.sh installed by Azure Linux bash RPM to align with upstream Flatcar behavior
    sudo rm -f "${root_fs_dir}/etc/profile.d/umask.sh"

    # Blacklist cfg80211 (wireless) — the Azure Linux kernel ships it as a
    # module but no WiFi hardware exists on cloud/VM targets, and the
    # regulatory.db firmware file is not present.
    sudo install -d -m 0755 "${root_fs_dir}/usr/lib/modprobe.d"
    echo "blacklist cfg80211" | sudo_clobber "${root_fs_dir}/usr/lib/modprobe.d/no-wifi.conf"
    sudo chmod 0644 "${root_fs_dir}/usr/lib/modprobe.d/no-wifi.conf"

    # Placeholder audit-rules.service - Azure Linux doesn't provide this but kola tests expect it as a common dependency
    if [[ ! -f "${root_fs_dir}/usr/lib/systemd/system/audit-rules.service" ]]; then
        info "RPM mode: Installing placeholder audit-rules.service"
        sudo cp "${BUILD_LIBRARY_DIR}/rpm/additional_files/audit-rules.service" "${root_fs_dir}/usr/lib/systemd/system/audit-rules.service"
    fi

    # Create tmpfiles.d entry for logrotate state directory.
    # The Azure Linux 3 logrotate RPM doesn't ship a tmpfiles.d drop-in,
    # so /var/lib/logrotate is not recreated at boot on ACL's immutable rootfs.
    echo 'd /var/lib/logrotate 0755 root root -' | sudo tee "${root_fs_dir}/usr/lib/tmpfiles.d/logrotate.conf" > /dev/null

    # Create /etc/resolv.conf symlink to point to systemd-resolved
    info "RPM mode: Configuring /etc/resolv.conf for systemd-resolved"
    sudo rm -f "${root_fs_dir}/etc/resolv.conf"
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf "${root_fs_dir}/etc/resolv.conf"

    # Enable serial-getty (autologin is controlled by generator based on cmdline)
    # arm64 uses ttyAMA0 (PL011 UART), x86_64 uses ttyS0 (8250 UART)
    local serial_tty="ttyS0"
    if [[ "${BOARD}" == "arm64-usr" ]]; then
        serial_tty="ttyAMA0"
    fi
    sudo mkdir -p "${root_fs_dir}/usr/lib/systemd/system/getty.target.wants"
    sudo ln -sf ../serial-getty@.service "${root_fs_dir}/usr/lib/systemd/system/getty.target.wants/serial-getty@${serial_tty}.service"

    # Remove ImportCredential= from getty services (credentials directory doesn't exist)
    info "RPM mode: Removing ImportCredential from getty services"
    sudo sed -i '/ImportCredential=/d' "${root_fs_dir}/usr/lib/systemd/system/getty@.service" 2>/dev/null || true
    sudo sed -i '/ImportCredential=/d' "${root_fs_dir}/usr/lib/systemd/system/serial-getty@.service" 2>/dev/null || true

    # Create /etc/profile.d directory for additional scripts
    sudo mkdir -p "${root_fs_dir}/etc/profile.d"

    # Workaround hanging issue when connecting via SAC/OneSAC serial console.
    # The console-login-helper-messages package's serial-console.sh uses
    # "read -sd" which blocks forever on non-interactive consoles (OneSAC,
    # DCM Explorer, QEMU text-file redirect). Adding a 1s timeout prevents
    # the hang. See AZL Bug 59925731, ACL Bug 18531.
    if [[ -f "${root_fs_dir}/etc/profile.d/serial-console.sh" ]]; then
        info "RPM mode: Fixing serial-console.sh read timeout"
        sudo sed -i 's/read -sd/read -t 1 -sd/g' \
            "${root_fs_dir}/etc/profile.d/serial-console.sh"
    fi

    # Ensure /root home directory exists with proper permissions
    sudo mkdir -p "${root_fs_dir}/root"
    sudo chmod 700 "${root_fs_dir}/root"

    # Disable read-ahead on squashfs-backed loop devices to prevent I/O errors.
    # The kernel's block-layer read-ahead can overshoot the end of
    # loop-backed squashfs files (sysext .raw images), producing:
    #   "I/O error, dev loopN, sector XXXX op 0x0:(READ)"
    # Setting read_ahead_kb=0 on squashfs loop devices avoids the overshoot.
    info "RPM mode: Adding udev rule to disable loop device read-ahead for sysext squashfs"
    sudo mkdir -p "${root_fs_dir}/etc/udev/rules.d"
    sudo tee "${root_fs_dir}/etc/udev/rules.d/60-loop-read-ahead.rules" > /dev/null <<'UDEV_LOOP'
# Prevent I/O errors from read-ahead overshooting loop-backed squashfs files
SUBSYSTEM=="block", KERNEL=="loop*", ENV{ID_FS_TYPE}=="squashfs", ATTR{queue/read_ahead_kb}="0"
UDEV_LOOP
    sudo chmod 644 "${root_fs_dir}/etc/udev/rules.d/60-loop-read-ahead.rules"

    # Remove ldconfig from the sysinit.target critical path.
    #
    # Problem: The upstream ldconfig.service has Before=sysinit.target, making
    # it a gate that blocks ALL other services until it finishes.  On Azure's
    # network-attached VHD, I/O contention during early boot inflates ldconfig
    # from ~32ms (idle disk) to ~6s, adding 6s to total boot time.
    #
    # Fix: Drop the Before=sysinit.target edge so ldconfig runs in parallel
    # with other services instead of blocking them.
    #
    # Why this is safe — the prebaked cache:
    #   run_ldconfig (in prod_image_util.sh) generates /etc/ld.so.cache at
    #   image build time.  This cache contains all base OS library paths.
    #   When we remove the boot gate, services that start before ldconfig
    #   finishes still get fast O(1) cache lookups for base libraries.
    #   Only sysext-only libraries (added after systemd-sysext.service merges
    #   them into /usr/lib) are not yet in the cache — the linker falls back
    #   to searching /usr/lib directly for those (functional, just slower).
    #   Once ldconfig completes, the cache is rebuilt with base + sysext
    #   libraries and all subsequent lookups use the full cache.
    #
    # Why the prebaked cache matters:
    #   Without it, removing the boot gate would leave every service doing
    #   expensive directory scans for ALL libraries until ldconfig finishes.
    #   The prebaked cache is what makes removing the gate safe.
    #
    # Why ldconfig still runs every boot despite the cache existing:
    #   The two conditions use the "|" (OR) prefix — either being true is
    #   enough.  ConditionNeedsUpdate=|/etc is always true on ACL because
    #   /etc is an overlayfs whose mtime changes every boot.  This is
    #   intentional: ldconfig must re-run to incorporate sysext libraries
    #   that weren't present at image build time.
    info "RPM mode: Installing ldconfig.service override (remove boot gating)"
    sudo install -d "${root_fs_dir}/etc/systemd/system"
    cat <<'EOF' | sudo tee "${root_fs_dir}/etc/systemd/system/ldconfig.service" > /dev/null
[Unit]
Description=Rebuild Dynamic Linker Cache
Documentation=man:ldconfig(8)

ConditionNeedsUpdate=|/etc
ConditionFileNotEmpty=|!/etc/ld.so.cache

DefaultDependencies=no
After=local-fs.target systemd-sysext.service
Conflicts=shutdown.target initrd-switch-root.target
Before=shutdown.target initrd-switch-root.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/ldconfig -X
EOF
    sudo chmod 0644 "${root_fs_dir}/etc/systemd/system/ldconfig.service"
}

# ── etcd: remove native server, keep etcdctl, prepare for Docker wrapper ─────
_configure_etcd_rpm() {
    local root_fs_dir="$1"

    # Remove etcd server and etcdutl binaries - we only need etcdctl from the etcd RPM.
    # The etcd server runs inside a Docker container via etcd-wrapper, not natively.
    if [[ -f "${root_fs_dir}/usr/bin/etcd" ]]; then
        info "RPM mode: Removing /usr/bin/etcd (etcd server runs in Docker via etcd-wrapper)"
        sudo rm -f "${root_fs_dir}/usr/bin/etcd"
    fi
    if [[ -f "${root_fs_dir}/usr/bin/etcdutl" ]]; then
        info "RPM mode: Removing /usr/bin/etcdutl (not needed)"
        sudo rm -f "${root_fs_dir}/usr/bin/etcdutl"
    fi
    # Also remove the native etcd.service - etcd-member.service (Docker-based) is used instead
    if [[ -f "${root_fs_dir}/usr/lib/systemd/system/etcd.service" ]]; then
        info "RPM mode: Removing native etcd.service (using etcd-member.service instead)"
        sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/etcd.service"
    fi
    # Remove the etcd preset file (refers to the native etcd.service we just removed)
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system-preset/50-etcd.preset"
    # Remove etcd config file (native etcd.service config, not used with etcd-wrapper)
    sudo rm -f "${root_fs_dir}/etc/etcd/etcd-default-conf.yml"

    # sysusers.d config to create the etcd user/group (needed by etcd-wrapper).
    # The etcd RPM doesn't create this user, but etcd-wrapper needs it for:
    #   - chown etcd:etcd on the data directory
    #   - id -u/-g to map the user into the Docker container
    # This MUST be in the rootfs (not the sysext) so systemd-sysusers creates
    # the user before the docker sysext is mounted.
    cat <<'SYSUSERS_EOF' | sudo tee "${root_fs_dir}/usr/lib/sysusers.d/etcd.conf" > /dev/null
u etcd - "etcd user" /var/lib/etcd
SYSUSERS_EOF

    # CLC transpiler generates ExecStart=/usr/lib/coreos/etcd-wrapper
    # Create compat symlink so /usr/lib/coreos -> flatcar resolves
    sudo ln -sfT flatcar "${root_fs_dir}/usr/lib/coreos"

    # etcd-member.service and etcd-wrapper.conf MUST be in the rootfs (not the
    # sysext) because Ignition runs before sysext merge. If the unit file only
    # exists in the sysext, Ignition cannot read its [Install] WantedBy= section
    # to create the multi-user.target.wants symlink, so the service never starts.
    local etcd_wrapper_src="${SCRIPT_ROOT}/sdk_container/src/third_party/coreos-overlay/app-admin/etcd-wrapper/files"
    local etcd_version="3.5.16"
    if [[ ! -d "${etcd_wrapper_src}" ]]; then
        die "etcd-wrapper source not found at ${etcd_wrapper_src}"
    fi
    # etcd-member.service (substitute image tag)
    sed "s|@ETCD_IMAGE_TAG@|v${etcd_version}|g" \
        "${etcd_wrapper_src}/etcd-member.service" \
        | sudo tee "${root_fs_dir}/usr/lib/systemd/system/etcd-member.service" > /dev/null
    # etcd-wrapper.conf -> /usr/lib/tmpfiles.d/ (creates /var/lib/etcd 0700 etcd:etcd)
    sudo cp "${etcd_wrapper_src}/etcd-wrapper.conf" "${root_fs_dir}/usr/lib/tmpfiles.d/etcd-wrapper.conf"
}

# Install flannel service units into the rootfs so Ignition can enable them.
# Same rationale as etcd-member.service above: Ignition runs before sysext
# merge, so it can't read [Install] sections from sysext-only unit files.
# The flannel-wrapper binary stays in the docker sysext (it depends on Docker).
_configure_flannel_services_rpm() {
    local root_fs_dir="$1"

    local flannel_wrapper_src="${SCRIPT_ROOT}/sdk_container/src/third_party/coreos-overlay/app-admin/flannel-wrapper/files"
    local flannel_version="0.14.0"
    if [[ ! -d "${flannel_wrapper_src}" ]]; then
        die "flannel-wrapper source not found at ${flannel_wrapper_src}"
    fi

    info "RPM mode: Installing flannel service units into rootfs (Ignition visibility)"
    # flanneld.service (substitute image tag)
    sed "s|@FLANNEL_IMAGE_TAG@|v${flannel_version}|g" \
        "${flannel_wrapper_src}/flanneld.service" \
        | sudo tee "${root_fs_dir}/usr/lib/systemd/system/flanneld.service" > /dev/null
    # flannel-docker-opts.service (substitute image tag)
    sed "s|@FLANNEL_IMAGE_TAG@|v${flannel_version}|g" \
        "${flannel_wrapper_src}/flannel-docker-opts.service" \
        | sudo tee "${root_fs_dir}/usr/lib/systemd/system/flannel-docker-opts.service" > /dev/null
}

# CIS Level 1 hardening
# Addresses CIS Azure Container Linux 4 Level 1 failures without affecting
# network connectivity or core system operation. All settings are safe for
# cloud/VM environments.
_configure_cis_hardening_rpm() {
    local root_fs_dir="$1"

    info "RPM mode: Applying CIS Level 1 hardening"

    # 1.1.1.1: Blacklist cramfs kernel module
    sudo install -d -m 0755 "${root_fs_dir}/usr/lib/modprobe.d"
    sudo tee "${root_fs_dir}/usr/lib/modprobe.d/cis-blacklist.conf" > /dev/null <<'MODPROBE_CIS'
# CIS 1.1.1.1 - Ensure cramfs kernel module is not available
install cramfs /bin/false
blacklist cramfs
MODPROBE_CIS
    sudo chmod 0644 "${root_fs_dir}/usr/lib/modprobe.d/cis-blacklist.conf"

    # NOT APPLICABLE to ACL
    # 1.2.1.2 (gpgcheck) / 1.2.1.3 (TDNF gpgcheck globally activated):
    #   ACL is an immutable OS with no package manager at runtime. There is no
    #   tdnf, no /etc/yum.repos.d, and no ability to install packages on a
    #   running system. These rules are false positives for ACL and should be
    #   excluded from the CIS benchmark or marked as not-applicable in the MOF.
    #
    # 2.2.17 (mail transfer agent local-only mode):
    #   Not implemented in the ComplianceEngine assessor. No MTA runs on ACL.
    #
    # 5.1.1 (cron daemon enabled):
    #   ACL does not ship cronie. No cron daemon exists to enable. Should be
    #   excluded from the ACL CIS benchmark.
    #
    # 5.5.2 (system accounts secured):
    #   Requires SCE script execution which the assessor does not support yet.
    #
    # 6.1.3.1 (access to all logfiles configured):
    #   Requires SCE script execution which the assessor does not support yet.

    # 1.4.x / 3.2.x: Sysctl hardening (network + ASLR)
    # Includes both IPv4 and IPv6 settings as required by the CIS benchmark.
    sudo install -d -m 0755 "${root_fs_dir}/usr/lib/sysctl.d"
    sudo tee "${root_fs_dir}/usr/lib/sysctl.d/90-cis-hardening.conf" > /dev/null <<'SYSCTL_CIS'
# CIS Azure Container Linux 4 - Level 1 sysctl hardening
#
# 1.4.1 - Address space layout randomization
kernel.randomize_va_space = 2

# 3.2.1 - Disable packet redirect sending
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# 3.2.2 - Ignore bogus ICMP error responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# 3.2.3 - Ignore broadcast ICMP requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# 3.2.4 - Do not accept ICMP redirects (IPv4 + IPv6)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# 3.2.5 - Do not accept secure ICMP redirects
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# 3.2.6 - Enable reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# 3.2.7 - Do not accept source-routed packets (IPv4 + IPv6)
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# 3.2.8 - Log suspicious (martian) packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# 3.2.9 - Enable TCP SYN cookies
net.ipv4.tcp_syncookies = 1

# 3.2.10 - Do not accept IPv6 router advertisements
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
SYSCTL_CIS
    sudo chmod 0644 "${root_fs_dir}/usr/lib/sysctl.d/90-cis-hardening.conf"

    # 1.4.3/1.4.4/1.4.5: Core dump hardening
    sudo install -d -m 0755 "${root_fs_dir}/etc/systemd/coredump.conf.d"
    sudo tee "${root_fs_dir}/etc/systemd/coredump.conf.d/cis.conf" > /dev/null <<'COREDUMP_CIS'
# CIS 1.4.4 / 1.4.5 - Disable core dump backtraces and storage
[Coredump]
Storage=none
ProcessSizeMax=0
COREDUMP_CIS
    sudo chmod 0644 "${root_fs_dir}/etc/systemd/coredump.conf.d/cis.conf"

    # CIS 1.4.3 - Limit core file size via limits.d
    sudo install -d -m 0755 "${root_fs_dir}/etc/security/limits.d"
    sudo tee "${root_fs_dir}/etc/security/limits.d/cis-core.conf" > /dev/null <<'LIMITS_CIS'
# CIS 1.4.3 - Ensure core file size is configured
* hard core 0
LIMITS_CIS
    sudo chmod 0644 "${root_fs_dir}/etc/security/limits.d/cis-core.conf"

    # 1.5.1/1.5.2: Login warning banners
    # The banner must NOT contain \v, \s, \m, \r or OS names (CIS regex check).
    # Disable issuegen completely so it doesn't overwrite /etc/issue at boot.
    # Note: finish_image_cleanup_issue_rpm() already removed package-provided
    # /etc/issue files and tmpfiles.d conflicts before systemd-tmpfiles ran.
    local banner_text="Authorized uses only. All activity may be monitored and reported."
    # Remove any residual symlink (issuegen.conf may have recreated it via tmpfiles).
    sudo rm -f "${root_fs_dir}/etc/issue" "${root_fs_dir}/etc/issue.net"
    echo "${banner_text}" | sudo tee "${root_fs_dir}/etc/issue" > /dev/null
    echo "${banner_text}" | sudo tee "${root_fs_dir}/etc/issue.net" > /dev/null
    sudo chmod 0644 "${root_fs_dir}/etc/issue" "${root_fs_dir}/etc/issue.net"
    # Remove issuegen so it doesn't regenerate /etc/issue at boot with OS info
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/issuegen.service"
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/issuegen.path"
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/multi-user.target.wants/issuegen.service"
    sudo rm -f "${root_fs_dir}/usr/lib/systemd/system/multi-user.target.wants/issuegen.path"
    sudo rm -f "${root_fs_dir}/usr/lib/flatcar/issuegen"
    sudo rm -f "${root_fs_dir}/usr/lib/udev/rules.d/90-issuegen.rules"
    # Remove issuegen tmpfiles.d config that creates /etc/issue → ../run/issue symlink
    sudo rm -f "${root_fs_dir}/usr/lib/tmpfiles.d/issuegen.conf"

    # 5.1.1: cron daemon — see NOT APPLICABLE section above

    # 5.4.1/5.4.2/5.4.3/5.4.4: PAM configuration
    # The CIS assessor checks BOTH /etc/pam.d/system-auth AND /etc/pam.d/system-password.
    # Azure Linux only ships system-auth; system-password does not exist.  Create it
    # so the assessor finds the expected PAM modules in both files.
    # NOTE: This is purely to satisfy CIS audit logic. The security posture is
    # unchanged -> PAM falls back to system-auth when system-password is absent,
    # so authentication is already correctly configured without this file.
    sudo install -d -m 0755 "${root_fs_dir}/etc/pam.d"

    # If system-password doesn't exist, create it as a copy of system-auth
    # so the PAM edits below apply to both files.
    if [[ ! -f "${root_fs_dir}/etc/pam.d/system-password" ]] && [[ -f "${root_fs_dir}/etc/pam.d/system-auth" ]]; then
        sudo cp "${root_fs_dir}/etc/pam.d/system-auth" "${root_fs_dir}/etc/pam.d/system-password"
    fi

    for pam_file in system-auth system-password; do
        local pam_path="${root_fs_dir}/etc/pam.d/${pam_file}"
        if [[ -f "${pam_path}" ]]; then
            # 5.4.1: Add pam_pwquality.so with retry=3 before pam_unix password line
            if ! sudo grep -q "pam_pwquality" "${pam_path}"; then
                sudo sed -i '/^password.*pam_unix.so/i password    requisite     pam_pwquality.so retry=3' \
                    "${pam_path}"
                sudo grep -q "pam_pwquality" "${pam_path}" \
                    || die "Failed to add pam_pwquality to ${pam_file} (anchor pattern '^password.*pam_unix.so' may have changed)"
            fi
            # 5.4.4: Add pam_pwhistory.so with remember=5 before pam_unix password line
            if ! sudo grep -q "pam_pwhistory" "${pam_path}"; then
                sudo sed -i '/^password.*pam_unix.so/i password    required      pam_pwhistory.so remember=5 use_authtok' \
                    "${pam_path}"
                sudo grep -q "pam_pwhistory" "${pam_path}" \
                    || die "Failed to add pam_pwhistory to ${pam_file} (anchor pattern '^password.*pam_unix.so' may have changed)"
            fi
            # 5.4.3: Ensure pam_unix.so has sha512
            if ! sudo grep -q "pam_unix.so.*sha512" "${pam_path}"; then
                sudo sed -i 's/\(^password.*pam_unix.so.*\)/\1 sha512/' "${pam_path}"
                sudo grep -q "pam_unix.so.*sha512" "${pam_path}" \
                    || die "Failed to add sha512 to pam_unix.so in ${pam_file}"
            fi
            # 5.4.2: Add pam_faillock.so auth lines if missing
            if ! sudo grep -q "pam_faillock" "${pam_path}"; then
                sudo sed -i '/^auth.*pam_unix.so/i auth        required      pam_faillock.so preauth deny=5 unlock_time=900' \
                    "${pam_path}"
                sudo sed -i '/^auth.*pam_unix.so/a auth        [default=die] pam_faillock.so authfail deny=5 unlock_time=900' \
                    "${pam_path}"
                # Add account line for faillock
                if ! sudo grep -q "account.*pam_faillock" "${pam_path}"; then
                    sudo sed -i '/^account.*pam_unix.so/i account     required      pam_faillock.so' \
                        "${pam_path}"
                fi
                sudo grep -q "pam_faillock.so preauth" "${pam_path}" \
                    || die "Failed to add pam_faillock to ${pam_file} (anchor pattern '^auth.*pam_unix.so' may have changed)"
            fi
        fi
    done

    # 5.4.1: Password creation requirements (pwquality)
    sudo install -d -m 0755 "${root_fs_dir}/etc/security"
    sudo tee "${root_fs_dir}/etc/security/pwquality.conf" > /dev/null <<'PWQUALITY_CIS'
# CIS 5.4.1 - Password creation requirements
minlen = 14
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
PWQUALITY_CIS
    sudo chmod 0644 "${root_fs_dir}/etc/security/pwquality.conf"

    # 5.4.2: Account lockout config (faillock.conf)
    sudo tee "${root_fs_dir}/etc/security/faillock.conf" > /dev/null <<'FAILLOCK_CIS'
# CIS 5.4.2 - Lockout for failed password attempts
deny = 5
unlock_time = 900
FAILLOCK_CIS
    sudo chmod 0644 "${root_fs_dir}/etc/security/faillock.conf"

    # 5.5.1.1: Password expiration
    if [[ -f "${root_fs_dir}/etc/login.defs" ]]; then
        sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   365/' "${root_fs_dir}/etc/login.defs"
        sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' "${root_fs_dir}/etc/login.defs"
    fi

    # 5.5.1.4: Inactive password lock via /etc/default/useradd
    # The CIS assessor checks /etc/default/useradd (NOT login.defs) for INACTIVE.
    sudo install -d -m 0755 "${root_fs_dir}/etc/default"
    if [[ -f "${root_fs_dir}/etc/default/useradd" ]]; then
        if sudo grep -q "^INACTIVE" "${root_fs_dir}/etc/default/useradd"; then
            sudo sed -i 's/^INACTIVE.*/INACTIVE=30/' "${root_fs_dir}/etc/default/useradd"
        else
            echo "INACTIVE=30" | sudo tee -a "${root_fs_dir}/etc/default/useradd" > /dev/null
        fi
    else
        sudo tee "${root_fs_dir}/etc/default/useradd" > /dev/null <<'USERADD_CIS'
# CIS 5.5.1.4 - Inactive password lock
INACTIVE=30
USERADD_CIS
    fi
    sudo chmod 0644 "${root_fs_dir}/etc/default/useradd"

    # 5.5.4: Default umask 027
    # Set in both login.defs (pam_umask) and profile.d (shell login).
    # Also configure sudo to reset umask to 022 so root-created files via sudo
    # remain world-readable (prevents kola tests from breaking when they read
    # files created by 'sudo coreos-cloudinit' etc.).
    sudo tee "${root_fs_dir}/etc/profile.d/cis-umask.sh" > /dev/null <<'UMASK_CIS'
# CIS 5.5.4 - Ensure default user umask is 027 or more restrictive
umask 027
UMASK_CIS
    sudo chmod 0644 "${root_fs_dir}/etc/profile.d/cis-umask.sh"
    if [[ -f "${root_fs_dir}/etc/login.defs" ]]; then
        sudo sed -i 's/^UMASK.*/UMASK           027/' "${root_fs_dir}/etc/login.defs"
    fi

    # 6.1.1.1.3/5/6: Journald configuration
    # The CIS assessor runs "systemd-analyze cat-config systemd/journald.conf"
    # and searches for uncommented parameters. Use a drop-in to override defaults.
    # 6.1.1.1.3: ForwardToSyslog — ACL has no rsyslog, so set to "no".
    sudo install -d -m 0755 "${root_fs_dir}/etc/systemd/journald.conf.d"
    cat <<'JOURNALD_CIS' | sudo tee "${root_fs_dir}/etc/systemd/journald.conf.d/cis.conf" > /dev/null
[Journal]
ForwardToSyslog=no
Storage=persistent
Compress=yes
JOURNALD_CIS
    sudo chmod 0644 "${root_fs_dir}/etc/systemd/journald.conf.d/cis.conf"

    # 7.2.8: Home directory permissions
    sudo chmod 0700 "${root_fs_dir}/root"
    if [[ -d "${root_fs_dir}/home" ]]; then
        sudo find "${root_fs_dir}/home" -maxdepth 1 -mindepth 1 -type d -exec chmod 0750 {} \;
    fi

    info "RPM mode: CIS Level 1 hardening complete"
}

# ── Orchestrator: post-tmpfiles image customization ──────────────────────────
finish_image_post_tmpfiles_rpm() {
    local root_fs_dir="$1"

    _remove_machine_id_rpm "${root_fs_dir}"
    _configure_ssh_rpm "${root_fs_dir}"
    _configure_sudo_rpm "${root_fs_dir}"
    _fix_ntp_nfs_services_rpm "${root_fs_dir}"
    _remove_unused_flatcar_components_rpm "${root_fs_dir}"
    _configure_disk_autogrow_rpm "${root_fs_dir}"
    _remove_unused_systemd_components_rpm "${root_fs_dir}"
    _configure_pcrlock_rpm "${root_fs_dir}"
    _configure_etcd_rpm "${root_fs_dir}"
    _configure_flannel_services_rpm "${root_fs_dir}"
    _configure_kdump_rpm "${root_fs_dir}"
    _configure_misc_rpm "${root_fs_dir}"
    _configure_cis_hardening_rpm "${root_fs_dir}"
    _generate_hwdb_rpm "${root_fs_dir}"
    _mask_core_sshkeys_rpm "${root_fs_dir}"
}

finish_image_backup_etc_rpm() {
    local root_fs_dir="$1"
    local DISTRO_SHARE="${root_fs_dir}${DISTRO_SHARE_DIR}"
    local ETC_FULL_PATH="${DISTRO_SHARE}/etc"

    # Uninstall repo definition packages — they are only needed during the
    # build for package installs and bootloader downloads.  Sysext builds
    # use the sysext base squashfs (created before this point) which still
    # contains the repos, so they are unaffected.  Removing these avoids
    # shipping internal build-infra details and trims the image.
    # Flags:
    #   --nodeps  — other packages may have weak dependencies on repos RPMs
    #   --noscripts — skip %preun/%postun scriptlets; the repos-shared
    #     scriptlet tries to run gpg-agent which fails in the chroot
    #     (no /dev/null).  Safe because we wipe /etc/yum.repos.d next.
    info "RPM mode: Uninstalling repo definition packages from image"
    local repo_pkgs
    repo_pkgs=$(sudo rpm --dbpath="${root_fs_dir}/var/lib/rpm" -qa "azurelinux-repos*" 2>/dev/null | sort -u)
    if [[ -n "${repo_pkgs}" ]]; then
        info "RPM mode: Removing repo packages: ${repo_pkgs//$'\n'/ }"
        if ! sudo rpm --root="${root_fs_dir}" --dbpath="/var/lib/rpm" -e --nodeps --noscripts ${repo_pkgs}; then
            error "RPM mode: Failed to remove some repo packages, aborting build"
            exit 1
        fi
    fi
    # Also remove the manually-created Nvidia repo file and any leftovers
    sudo rm -rf "${root_fs_dir}/etc/yum.repos.d"

    # Emit the rpmdb as an IC sidecar artifact alongside the VHD.
    local rpmdb_src="${root_fs_dir}/var/lib/rpm/rpmdb.sqlite"
    if [[ -f "${rpmdb_src}" ]]; then
        if [[ -z "${BUILD_DIR:-}" ]]; then
            die "RPM mode: BUILD_DIR is not set — cannot save rpmdb IC sidecar"
        fi
        info "RPM mode: Saving rpmdb IC sidecar to ${BUILD_DIR}/acl_production_image_rpmdb.sqlite"
        sudo cp "${rpmdb_src}" "${BUILD_DIR}/acl_production_image_rpmdb.sqlite" \
            || die "RPM mode: Failed to save rpmdb sidecar to ${BUILD_DIR}"
        sudo chmod 644 "${BUILD_DIR}/acl_production_image_rpmdb.sqlite" \
            || die "RPM mode: Failed to chmod rpmdb sidecar"
    fi

    # Bulk-copy all of /etc to ${DISTRO_SHARE_DIR}/etc.
    # This is the overlay lowerdir — at boot, /etc is a tmpfs overlay
    # whose lower layer is this directory.  Mirrors the Portage-mode
    # "sudo cp -a /etc ${DISTRO_SHARE_DIR}/etc" in build_image_util.sh.
    info "RPM mode: Copying /etc to ${ETC_FULL_PATH} for overlay lowerdir"
    sudo rm -rf "${ETC_FULL_PATH}"
    sudo cp -a "${root_fs_dir}/etc" "${ETC_FULL_PATH}"
}

# Escape a string for JSON - handles quotes, backslashes, and control characters
json_escape() {
    local str="$1"
    # Remove control characters (except newline which we'll handle)
    str=$(echo "$str" | tr -d '\000-\011\013-\037')
    # Escape backslashes first, then quotes, then convert newlines
    str=$(echo "$str" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')
    echo "$str"
}

# Normalize RPM license strings to Portage license file names
# RPM uses SPDX expressions like "GPL-2.0-or-later AND MIT" or "GPLv2+ or LGPLv2+"
# This function extracts individual license names and maps them to Portage equivalents
normalize_rpm_license() {
    local lic="$1"

    # Replace SPDX operators with spaces (use word boundaries via spaces)
    # Handle: " AND ", " OR ", " WITH ", " and ", " or ", " with "
    local normalized
    normalized=$(echo " $lic " | \
        sed -e 's/ AND / /g' \
            -e 's/ OR / /g' \
            -e 's/ WITH / /g' \
            -e 's/ and / /g' \
            -e 's/ or / /g' \
            -e 's/ with / /g' \
            -e 's/[(),]/ /g' \
            -e 's/  */ /g' \
            -e 's/^ *//' \
            -e 's/ *$//')

    # Map common RPM/SPDX license names to Portage license file names
    local result=""
    for l in $normalized; do
        local mapped="$l"
        case "$l" in
            # Skip version numbers, fragments, and empty strings
            [0-9]*|""|2-Clause|3-Clause) continue ;;
            # SPDX to Portage mappings - GPL family
            GPL-2.0-only|GPL-2.0) mapped="GPL-2" ;;
            GPL-2.0-or-later|GPL-2.0+) mapped="GPL-2+" ;;
            GPL-3.0-only|GPL-3.0) mapped="GPL-3" ;;
            GPL-3.0-or-later|GPL-3.0+) mapped="GPL-3+" ;;
            GPLv2) mapped="GPL-2" ;;
            GPLv2+) mapped="GPL-2+" ;;
            GPLv3) mapped="GPL-3" ;;
            GPLv3+) mapped="GPL-3+" ;;
            GPL+) mapped="GPL-2+" ;;
            GPL2) mapped="GPL-2" ;;
            # LGPL family
            LGPL-2.0-only|LGPL-2.0) mapped="LGPL-2" ;;
            LGPL-2.0-or-later|LGPL-2.0+) mapped="LGPL-2+" ;;
            LGPL-2.1-only|LGPL-2.1) mapped="LGPL-2.1" ;;
            LGPL-2.1-or-later|LGPL-2.1+) mapped="LGPL-2.1+" ;;
            LGPL-3.0-only|LGPL-3.0) mapped="LGPL-3" ;;
            LGPL-3.0-or-later|LGPL-3.0+) mapped="LGPL-3+" ;;
            LGPLv2) mapped="LGPL-2" ;;
            LGPLv2+) mapped="LGPL-2+" ;;
            LGPLv2.1) mapped="LGPL-2.1" ;;
            LGPLv2.1+) mapped="LGPL-2.1+" ;;
            LGPLv3) mapped="LGPL-3" ;;
            LGPLv3+) mapped="LGPL-3+" ;;
            # Apache
            Apache-2.0|Apache-2.0\)) mapped="Apache-2.0" ;;
            ASL|ASL2.0) mapped="Apache-2.0" ;;
            # BSD family
            BSD) mapped="BSD" ;;
            BSD-2-Clause) mapped="BSD-2" ;;
            BSD-3-Clause|BSD-3) mapped="BSD" ;;
            BSD-4-Clause) mapped="BSD-4" ;;
            # MIT and similar
            MIT|MIT\)|MIT-CMU) mapped="MIT" ;;
            X11|XFree86) mapped="MIT" ;;
            # Mozilla
            MPL-2.0|MPL-2.0\)|MPLv2.0) mapped="MPL-2.0" ;;
            # Other common licenses
            ISC) mapped="ISC" ;;
            Zlib|Zlib\)|zlib) mapped="ZLIB" ;;
            PSF|PSF-2.0) mapped="PSF-2" ;;
            Artistic|Artistic\)|Artistic-1.0) mapped="Artistic" ;;
            Artistic-2.0) mapped="Artistic-2" ;;
            CC0|CC0-1.0) mapped="CC0-1.0" ;;
            CC-BY-3.0) mapped="CC-BY-3.0" ;;
            CC-BY-4.0|CC-BY) mapped="CC-BY-SA-3.0" ;;
            GFDL-1.3-or-later) mapped="FDL-1.3+" ;;
            GFDL-1.3-no-invariants-or-later) mapped="FDL-1.3+" ;;
            BSL-1.0|BSL-1.0\)) mapped="Boost-1.0" ;;
            Unlicense|Unlicense\)) mapped="public-domain" ;;
            OpenSSL|OpenSSL\)) mapped="openssl" ;;
            OpenLDAP) mapped="OPENLDAP" ;;
            curl) mapped="curl" ;;
            Vim) mapped="vim" ;;
            Inner-Net) mapped="inner-net" ;;
            # Public domain variations
            Public|Domain|public|domain) mapped="public-domain" ;;
            LicenseRef-Fedora-Public-Domain) mapped="public-domain" ;;
            # Exceptions and modifiers - skip these
            LLVM-exception|eCos-exception-2.0) continue ;;
            exceptions|modification|permitted|advertising|no|Redistributable|Redistributable,) continue ;;
            # Handle parenthesized versions that sneak through
            \(GPL+|\(GPLv2|\(GPLv2+|\(MIT|\(Apache-2.0|\(LGPLv3+|\(MPL-2.0|\(Unlicense|\(ASL) continue ;;
            GPLv2+\)|LGPLv2+\)|LGPLv3+\)) continue ;;
            GPLv2,) mapped="GPL-2" ;;
            # Licenses that have different names in portage-stable
            AFL) mapped="AFL-2.1" ;;
            Beerware) mapped="BEER-WARE" ;;
            # Licenses that don't have portage equivalents - suppress warnings
            # TTWL, HSRL, Rdisc, UCD are obscure licenses from specific packages
            # Unknown means the package has no specified license
            TTWL|HSRL|Rdisc|UCD|Unknown|Nmap|pubkey) continue ;;
        esac
        if [[ -n "$mapped" ]]; then
            result="$result $mapped"
        fi
    done
    echo "$result"
}
