#!/bin/bash

set -euo pipefail

rootfs="${1}"
PACKAGE_SOURCE_MODE="${PACKAGE_SOURCE_MODE:-PORTAGE}"
script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

to_delete=(
    /usr/include
    /usr/lib/debug
    /usr/share/gdb
    /usr/lib64/pkgconfig
)

rm -rf "${to_delete[@]/#/${rootfs}}"

ln -sf /usr/bin/true "${rootfs}/usr/bin/eject"

# At runtime we need the agent to write systemd.service to /etc but during
# package creation it needs to be /usr/lib. waagent uses the same function in
# both cases, so mangle manually.
mkdir -p "${rootfs}"/usr/lib/systemd/system
cp -a "${rootfs}"/{etc,usr/lib}/systemd/system/.

# Remove test stuff from python - it's quite large.
for p in "${rootfs}"/usr/lib/python*; do
    if [[ ! -d ${p} ]]; then
        continue
    fi
    # find directories named tests or test and remove them (-prune
    # avoids searching below those directories)
    find "${p}" \( -name tests -o -name test \) -type d -prune -exec rm -rf '{}' '+'
done

# Enable symlinks for sysext-delivered services (chronyd, waagent).
# Preset-all runs before sysext merge so never creates these; without them
# "systemctl is-enabled <unit>" reports "disabled".  Uses "L" (not "L+")
# so an admin mask/redirect survives reboots.
if [[ -f "${script_dir}/sysext-enable.conf" ]]; then
    mkdir -p "${rootfs}/usr/lib/tmpfiles.d"
    cp "${script_dir}/sysext-enable.conf" "${rootfs}/usr/lib/tmpfiles.d/sysext-enable.conf"
fi

# RPM-specific changes if in RPM mode
if [[ "${PACKAGE_SOURCE_MODE}" == "RPM" ]]; then
    source "${script_dir}/manglefs_rpm.sh"
fi
