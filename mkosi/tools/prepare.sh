#!/bin/bash
# Shared PrepareScripts= hook: Distribution=custom installs nothing, so read
# Packages=/RemovePackages= back from the config and emerge them here.

set -euo pipefail

[[ "${MKOSI_DEBUG:-0}" == "1" ]] && set -x

[ "$1" = final ] || exit 0

. "${SRCDIR}/lib/lib.sh"

# build_sysext emerges with the board config, so only the image gets a configroot.
if [[ "$(jq -r .Format "$MKOSI_CONFIG")" != sysext ]]; then
    create_configroot "$FLATCAR_UPDATE_GROUP"
fi

mkosi_config_read_array() { jq -r --arg k "$1" '.[$k] // [] | .[]' "$MKOSI_CONFIG"; }
image="$(jq -r '.Image // "main"' "$MKOSI_CONFIG")"
# Not mkosi's build-overlay semantics; source builds go through
# FLATCAR_SOURCE_BUILD below, which builds the Packages= closure itself.
for setting in BuildPackages VolatilePackages; do
    mapfile -t unsupported < <(mkosi_config_read_array "$setting")
    if [ "${#unsupported[@]}" -gt 0 ]; then
        echo "prepare[$image]: $setting= is not currently supported in Flatcar mkosi setup" >&2
        exit 1
    fi
done

mapfile -t install < <(mkosi_config_read_array Packages)
mapfile -t remove  < <(mkosi_config_read_array RemovePackages)

# Build missing binpkgs first; the install below stays --usepkgonly, which keeps
# compilers and DEPENDs out of the image.
if [ "${FLATCAR_SOURCE_BUILD:-1}" = 1 ] && [ "${#install[@]}" -gt 0 ]; then
    echo "prepare[$image]: source build enabled, emerging ${install[*]} into ${BOARD_ROOT}"
    if [ "$(jq -r '.Format' "$MKOSI_CONFIG")" = sysext ]; then
        # As build_sysext_packages: merging the sysext packages themselves into
        # the board collides (e.g. the nvidia-drivers variants).
        export FEATURES="${FEATURES:+${FEATURES} }binpkg-multi-instance"
        emerge_from_source --onlydeps "${install[@]}"
        emerge_from_source --buildpkgonly "${install[@]}"
    else
        emerge_from_source "${install[@]}"
    fi
fi

[ "${#install[@]}" -gt 0 ] && mkosi-install "${install[@]}"
[ "${#remove[@]}"  -gt 0 ] && mkosi-remove  "${remove[@]}"

# mkosi looks for kernels in /usr/lib/modules/<kver>/, Flatcar installs them to
# /usr/boot.
for kver_dir in "${BUILDROOT}"/usr/lib/modules/*/; do
    [ -d "${kver_dir}" ] || continue
    kver="$(basename "${kver_dir}")"
    for kt in vmlinuz vmlinux; do
        src="${BUILDROOT}/usr/boot/${kt}-${kver}"
        [ -e "${src}" ] || src="${BUILDROOT}/usr/boot/${kt}"
        [ -e "${src}" ] || continue
        [ -e "${kver_dir}${kt}" ] || cp -a "${src}" "${kver_dir}${kt}"
    done
done

exit 0
