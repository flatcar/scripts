#!/bin/bash

set -euo pipefail

rootfs="${1}"

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
