#!/usr/bin/env bash
# Keep the image's pkgdb as <image>-pkgdb, upstream's _pkginfo.raw: sysexts drop
# /var, but licenses and dependent sysexts need it. Only packages new over the
# BaseTrees= are kept.
set -euo pipefail

[[ "${MKOSI_DEBUG:-0}" == "1" ]] && set -x

root="${BUILDROOT:?BUILDROOT must be set by mkosi}"
# mkosi exports SUBIMAGE for every non-main image.
image="${SUBIMAGE:?SUBIMAGE must be set by mkosi}"
src="${root}/var/db/pkg"
dst="${SRCDIR:?}/mkosi.output/${image}-pkgdb"

rm -rf "${dst}"
# Created even when empty: dependent sysexts list it in BaseTrees=.
mkdir -p "${dst}/var/db/pkg"
[[ -d "${src}" ]] || { echo "[pkgdb] ${image}: no /var/db/pkg, nothing to save"; exit 0; }

lower_pkgdbs=()
while IFS= read -r tree; do
    lower="${SRCDIR}/mkosi.output/${tree##*/}/var/db/pkg"
    [[ -d "${lower}" ]] && lower_pkgdbs+=("${lower}")
done < <(jq -r '.BaseTrees // [] | .[]' "${MKOSI_CONFIG}")

count=0
while IFS= read -r pkg; do
    for lower in "${lower_pkgdbs[@]}"; do
        [[ -d "${lower}/${pkg}" ]] && continue 2
    done
    mkdir -p "${dst}/var/db/pkg/${pkg%/*}"
    cp -a "${src}/${pkg}" "${dst}/var/db/pkg/${pkg}"
    count=$((count + 1))
done < <(cd "${src}" && find . -mindepth 2 -maxdepth 2 -type d -printf '%P\n' | sort)

echo "[pkgdb] ${image}: saved ${count} package(s) to $(basename "${dst}")"
