#!/bin/bash

set -e
source /tmp/chroot-functions.sh
source /tmp/toolchain_util.sh

# A note on packages:
# The default PKGDIR is /usr/portage/packages
# To make sure things are uploaded to the correct places we split things up:
# crossdev build packages use ${PKGDIR}/crossdev (uploaded to SDK location)
# build deps in crossdev's sysroot use ${PKGDIR}/cross/${CHOST} (no upload)
# native toolchains use ${PKGDIR}/target/${BOARD} (uploaded to board location)

configure_target_root() {
    local board="$1"
    local cross_chost=$(get_board_chost "$1")
    local profile=$(get_board_profile "${board}")

    CBUILD="$(portageq envvar CBUILD)" \
        CHOST="${cross_chost}" \
        ROOT="/build/${board}" \
        SYSROOT="/build/${board}" \
        _configure_sysroot "${profile}"
}

build_target_toolchain() {
    local board="$1"
    local ROOT="/build/${board}"
    local SYSROOT="/usr/$(get_board_chost "${board}")"

    # copy libraries and binaries from sysroot to root - sysroot may
    # be using split-usr, whereas root does not, so take this into
    # account
    (
        shopt -s nullglob
        local d f
        local -a files
        for d in "${SYSROOT}"/lib* "${SYSROOT}"/usr/lib* "${SYSROOT}"/{usr/,}{bin,sbin}; do
            if [[ ! -d ${d} ]]; then
                continue
            fi
            files=( "${d}"/* )
            if [[ ${#files[@]} -gt 0 ]]; then
                f=${d##*/}
                cp -at "${ROOT}/usr/${f}" "${files[@]}"
            fi
        done
    )
    cp -at "${ROOT}"/usr "${SYSROOT}"/usr/include

    # --root is required because run_merge overrides ROOT=
    PORTAGE_CONFIGROOT="$ROOT" \
        run_merge -u --root="$ROOT" --sysroot="$ROOT" "${TOOLCHAIN_PKGS[@]}"
}

configure_crossdev_overlay / /usr/local/portage/crossdev

for board in $(get_board_list); do
    echo "Building native toolchain for ${board}"
    target_pkgdir="$(portageq envvar PKGDIR)/target/${board}"
    PKGDIR="${target_pkgdir}" configure_target_root "${board}"
    PKGDIR="${target_pkgdir}" build_target_toolchain "${board}"
done
