#!/bin/bash

. "$(dirname "$0")/../common.sh" || exit 1
. "${BUILD_LIBRARY_DIR}/toolchain_util.sh" || exit 1

# Script must run inside the chroot
assert_inside_chroot

assert_not_root_user

for REPO_PATH in "${REPO_ROOT}"/src/third_party/*; do
    case ${REPO_PATH} in
        */portage-stable|*/gentoo) continue;;
    esac
    REPO_NAME=$(<"${REPO_PATH}/profiles/repo_name")
    CONF=$(prioritise_non_gentoo_pkgs "${REPO_ROOT}" "${REPO_NAME}")
    if [[ -e ${CONF} ]]; then
        for BOARD_ROOT in "${BOARD_NAMES[@]/#/'/build/'}"; do
            if [[ -n ${BOARD_ROOT} ]]; then
                BOARD_CONF=${BOARD_ROOT}${CONF}
                sudo mkdir -p "${BOARD_CONF%/*}"
                sudo ln -snf "${CONF}" "${BOARD_CONF}"
            fi
        done
    fi
done
