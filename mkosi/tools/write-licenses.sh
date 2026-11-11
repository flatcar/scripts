#!/usr/bin/env bash
# licenses.json and the extra SLSA files, from upstream's write_licenses over
# the image's pkgdb plus the named built-in sysexts', as create_prod_image does.
set -eo pipefail

[[ "${MKOSI_DEBUG:-0}" == "1" ]] && set -x

. "${SRCDIR}/lib/lib.sh"
setup_configroot
# Base's extract_prod_gcc did this in its own configroot.
package_provided "$(get_binary_pkg sys-devel/gcc)"

root="${BUILDROOT:?BUILDROOT must be set by mkosi}"

outdir="${SRCDIR}/mkosi.output"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

# Union pkgdb: the image's own, plus each built-in sysext's saved one.
merged="${work}/merged"
mkdir -p "${merged}/var/db"
cp -a "${root}/var/db/pkg" "${merged}/var/db/pkg"

for name in "$@"; do
    d="${outdir}/${name}-sysext-pkgdb"
    [[ -d "${d}/var/db/pkg" ]] || { echo "[licenses] ERROR: ${d} missing" >&2; exit 1; }
    cp -a "${d}/var/db/pkg"/. "${merged}/var/db/pkg/"
    echo "[licenses] merged ${name}"
done

json="${work}/licenses.json"
write_licenses "${merged}" "${json}"
insert_licenses "${json}" "${root}"
# SLSA for packages only in the initrd/ESP.
insert_extra_slsa "${root}"

pkgs=$(grep -c '"project"' "${json}" 2>/dev/null || true)
echo "[licenses] wrote licenses.json.bz2 (${pkgs:-0} packages)"
