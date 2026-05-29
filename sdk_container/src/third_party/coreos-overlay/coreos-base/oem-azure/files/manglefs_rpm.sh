# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Create waagent sub-dir if it doesn't exist
mkdir -p "${rootfs}/usr/lib/waagent"
# Move waagent.conf out of /etc to /usr/lib to preserve it in sysext
if [[ -f "${rootfs}/etc/waagent.conf" ]]; then
    mv "${rootfs}/etc/waagent.conf" "${rootfs}/usr/lib/waagent/waagent.conf"
fi

# Patch waagent service file by removing ConditionPathExists line
if [[ -f "${rootfs}/usr/lib/systemd/system/waagent.service" ]]; then
    sed -i \
        '/^ConditionPathExists=/d' \
        "${rootfs}/usr/lib/systemd/system/waagent.service"
fi

# Patch waagent service file to create symlink back to /etc/waagent.conf at ExecStartPre
if [[ -f "${rootfs}/usr/lib/systemd/system/waagent.service" ]]; then
    # Insert ExecStartPre lines after the [Service] header
    sed -i \
        '/^\[Service\]$/a ExecStartPre=/bin/bash -c '\''if [[ ! -e /etc/waagent.conf ]]; then ln -sf /usr/lib/waagent/waagent.conf /etc/waagent.conf; fi'\''' \
        "${rootfs}/usr/lib/systemd/system/waagent.service"

    sed -i \
        '/^\[Service\]$/a ExecStartPre=/bin/bash -c '\''if [[ ! -e /oem/waagent.conf ]]; then ln -sf /etc/waagent.conf /oem/waagent.conf; fi'\''' \
        "${rootfs}/usr/lib/systemd/system/waagent.service"
fi

# Create chrony sub-dir if it doesn't exist
mkdir -p "${rootfs}/usr/lib/chrony"
# Move chrony.conf out of /etc to /usr/lib to preserve it in sysext
if [[ -f "${rootfs}/etc/chrony.conf" ]]; then
    mv "${rootfs}/etc/chrony.conf" "${rootfs}/usr/lib/chrony/chrony.conf"
fi

# Move chrony environment file out of /etc to /usr/lib to preserve it in sysext
if [[ -f "${rootfs}/etc/sysconfig/chronyd" ]]; then
    mv "${rootfs}/etc/sysconfig/chronyd" "${rootfs}/usr/lib/chrony/chronyd"
fi

# Move NTP keys file out of /etc to /usr/lib to preserve it in sysext
if [[ -f "${rootfs}/etc/chrony.keys" ]]; then
    mv "${rootfs}/etc/chrony.keys" "${rootfs}/usr/lib/chrony/chrony.keys"
fi

# Patch chrony service file for chronyd to point to new environment file and config
if [[ -f "${rootfs}/usr/lib/systemd/system/chronyd.service" ]]; then
    # Update EnvironmentFile path
    sed -i \
        's|^EnvironmentFile=-/etc/sysconfig/chronyd$|EnvironmentFile=-/usr/lib/chrony/chronyd|' \
        "${rootfs}/usr/lib/systemd/system/chronyd.service"

    # Update ExecStart to use -f /usr/lib/chrony/chrony.conf
    sed -i \
        's|^ExecStart=/usr/sbin/chronyd $OPTIONS$|ExecStart=/usr/sbin/chronyd -f /usr/lib/chrony/chrony.conf $OPTIONS|' \
        "${rootfs}/usr/lib/systemd/system/chronyd.service"
fi

# Copy Azure-optimized chrony.conf from this directory.
# Overwrites the RPM default that manglefs already moved from /etc.
# Key differences: makestep 1.0 -1 (always-step), PTP refclock for Hyper-V clock.

# Copy Azure-optimized chrony.conf to /usr/lib/chrony/chrony.conf
if [[ -f "${script_dir}/chrony.conf" ]]; then
    cp "${script_dir}/chrony.conf" "${rootfs}/usr/lib/chrony/chrony.conf"
fi

# chronyd.service drop-in (Wants/After dev-ptp_hyperv.device)
if [[ -f "${script_dir}/chrony-hyperv.conf" ]]; then
    mkdir -p "${rootfs}/usr/lib/systemd/system/chronyd.service.d"
    cp "${script_dir}/chrony-hyperv.conf" \
       "${rootfs}/usr/lib/systemd/system/chronyd.service.d/"
fi

# Chrony tmpfiles: /var/lib/chrony dir + /etc/chrony.keys copy-on-boot
if [[ -f "${script_dir}/var-chrony.conf" ]]; then
    mkdir -p "${rootfs}/usr/lib/tmpfiles.d"
    cp "${script_dir}/var-chrony.conf" "${rootfs}/usr/lib/tmpfiles.d/chrony.conf"
fi

# etc-chrony.conf is skipped - it creates a symlink to a Flatcar-specific
# path (/usr/share/oem-azure/) that doesn't exist on ACL, and chronyd.service
# is already patched above to use -f /usr/lib/chrony/chrony.conf directly.

# Remove the "dangling" os-release file because sysexts are not allowed to have
# a /usr/lib/os-release file. Probably brought over by azurelinux-release dependency.
os_release="${rootfs}/usr/lib/os-release"
if [[ -f "${os_release}" ]]; then
    echo "  Removing ${os_release}"
    rm -f "${os_release}"
fi

# OEM sysexts preserve python3 for Azure guest tooling, so create the
# compatibility symlink for python since it only ships with python3.
if [[ -x "${rootfs}/usr/bin/python3" && ! -e "${rootfs}/usr/bin/python" ]]; then
    ln -sf python3 "${rootfs}/usr/bin/python"
fi
