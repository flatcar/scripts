#!/usr/bin/env bash
# build_sysext's tail: the mangle script, then its extension-release instead of
# mkosi's. A finalize script sees only the overlay's upper layer, like upstream.
set -euo pipefail

[[ "${MKOSI_DEBUG:-0}" == "1" ]] && set -x

. "${SRCDIR}/lib/lib.sh"

SYSEXT_ID="$(jq -r '.Output' "${MKOSI_CONFIG}")"
mapfile -t packages < <(jq -r '.Packages[]' "${MKOSI_CONFIG}")
mangle="${BUILD_LIBRARY_DIR}/sysext_mangle_${SYSEXT_ID}"
# OEM sysexts use their metapackage's files/manglefs.sh (create_oem_sysexts).
if [[ ${SYSEXT_ID} == oem-* ]]; then
  mangle="$(portageq get_repo_path / coreos-overlay)/${packages[0]}/files/manglefs.sh"
fi
if [[ -x "${mangle}" ]]; then
  "${mangle}" "${BUILDROOT}"
else
  echo "[mangle] ${SYSEXT_ID}: no ${mangle##*/}"
fi

# As build_sysext: opaque dirs would hide base's contents. mkosi's overlay
# uses userxattr, so check the user namespace too.
find "${BUILDROOT}" -xdev -type d -print0 | while IFS= read -r -d '' dir; do
  for ns in user trusted; do
    if [[ "$(getfattr -h --only-values -n "${ns}.overlay.opaque" "${dir}" 2>/dev/null)" == y ]]; then
      setfattr -h -x "${ns}.overlay.opaque" "${dir}"
    fi
  done
done

# build_sysext:236-240, 293-305 from here on.
ARCH="$(jq -r '.Architecture' "${MKOSI_CONFIG}")"
FLATCAR_VERSION_ID="$(. "${SRCDIR}/mkosi.output/base/usr/lib/os-release"; echo "${VERSION_ID}")"

# If there's only one package, grab its metadata for the sysext.
unset PVR HOMEPAGE SYSEXT_NAME
if [[ ${#packages[@]} -eq 1 ]]; then
  pkgdb="${SRCDIR}/mkosi.output/${SUBIMAGE:?}-pkgdb"
  CPV=$(portageq best_version "${pkgdb}" "${packages[0]}")
  IFS=$'\n' read -r -d '' PVR HOMEPAGE SYSEXT_NAME < <(portageq metadata "${pkgdb}" installed "${CPV}" PVR HOMEPAGE SYSEXT_NAME; printf '\0')
fi

grep . <<EOF | install -m0644 -D /dev/stdin "${BUILDROOT}/usr/lib/extension-release.d/extension-release.${SYSEXT_ID}"
ID='flatcar'
${VERSION_FIELD_OVERRIDE:-VERSION_ID}=${FLATCAR_VERSION_ID@Q}
ARCHITECTURE=${ARCH@Q}
EXTENSION_RELOAD_MANAGER=1
SYSEXT_ID=${SYSEXT_ID@Q}
${SYSEXT_NAME:+SYSEXT_NAME=${SYSEXT_NAME@Q}}
${PVR:+SYSEXT_VERSION_ID=${PVR@Q}}
${HOMEPAGE:+SYSEXT_HOME_URL=${HOMEPAGE@Q}}
SYSEXT_BUG_REPORT_URL='https://issues.flatcar.org'
EOF
