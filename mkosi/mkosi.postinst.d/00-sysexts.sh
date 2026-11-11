#!/usr/bin/env bash
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# Bake the built-in sysexts into /usr/share/flatcar/sysext with an
# /etc/extensions symlink each, as sysext_prod_builder does.
. "${SRCDIR}/lib/postinst.sh"

sysext_dir="${root_fs_dir}/usr/share/flatcar/sysext"
ext_dir="${root_fs_dir}/etc/extensions"
install -d -m 0755 "${sysext_dir}" "${ext_dir}"

for name in "${builtin_sysexts[@]}"; do
    src="${SRCDIR}/mkosi.output/${name}.raw"
    if [[ ! -f "${src}" ]]; then
        echo "[builtin-sysext] ERROR: ${src} not found — was the ${name}-sysext sub-image built?" >&2
        exit 1
    fi

    install -m 0644 "${src}" "${sysext_dir}/${name}.raw"
    ln -sf "/usr/share/flatcar/sysext/${name}.raw" "${ext_dir}/${name}.raw"
    echo "[builtin-sysext] baked ${name}.raw into /usr + /etc/extensions symlink"
done
