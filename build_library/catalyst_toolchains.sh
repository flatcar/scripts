#!/bin/bash

set -e
source /tmp/chroot-functions.sh
source /tmp/toolchain_util.sh
source /tmp/break_dep_loop.sh

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

    function btt_emerge() {
        # --root is required because run_merge overrides ROOT=
        PORTAGE_CONFIGROOT="$ROOT" run_merge --root="$ROOT" --sysroot="$ROOT" "${@}"
    }

    # install baselayout first - for some reason this is pulled into
    # the dependency chain when building toolchain
    btt_emerge --oneshot --nodeps sys-apps/baselayout

    # copy libraries and binaries from sysroot to root - sysroot seems to be
    # split-usr, whereas root does not, so take this into account
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

    local -a args_for_bdl=()
    if [[ -n ${clst_VERBOSE} ]]; then
        args_for_bdl+=(-v)
    fi
    function btt_bdl_portageq() {
        ROOT=${ROOT} SYSROOT=${ROOT} PORTAGE_CONFIGROOT=${ROOT} portageq "${@}"
    }
    function btt_bdl_equery() {
        ROOT=${ROOT} SYSROOT=${ROOT} PORTAGE_CONFIGROOT=${ROOT} equery "${@}"
    }
    # Breaking the following loops here:
    #
    # TODO: list them
    args_for_bdl+=(
        net-libs/nghttp2 systemd
        sys-apps/systemd cryptsetup,tpm
        sys-apps/util-linux cryptsetup,systemd,udev
        sys-fs/cryptsetup systemd,udev
        sys-fs/lvm2 systemd
        sys-libs/pam systemd
    )
    BDL_ROOT=${ROOT} \
    BDL_PORTAGEQ=btt_bdl_portageq \
    BDL_EQUERY=btt_bdl_equery \
    BDL_EMERGE=btt_emerge \
        break_dep_loop "${args_for_bdl[@]}"
    unset btt_bdl_portageq btt_bdl_equery

    btt_emerge --changed-use --update --deep "${TOOLCHAIN_PKGS[@]}"
    unset btt_emerge
}

configure_crossdev_overlay / /usr/local/portage/crossdev

for board in $(get_board_list); do
    echo "Building native toolchain for ${board}"
    target_pkgdir="$(portageq envvar PKGDIR)/target/${board}"
    PKGDIR="${target_pkgdir}" configure_target_root "${board}"
    PKGDIR="${target_pkgdir}" build_target_toolchain "${board}"
done
