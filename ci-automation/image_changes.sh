#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# image_changes() should be called w/ the positional INPUT parameters below.

# OS image differences display stub.
#   This script will display the differences between the last released image and the currently built one.
#
# PREREQUISITES:
#
#   1. Artifacts describing the built image (kernel config, contents, packages, etc.) must be present in build cache server.
#   2. Scripts repo version tag of OS image version to be built is available and checked out.
#
# INPUT:
#
#   1. Architecture (ARCH) of the TARGET OS image ("arm64", "amd64").
#
# OPTIONAL INPUT:
#
#   (none)
#
# OUTPUT:
#
#   1. Currently the script prints the image differences compared to the last release and the changelog for the release notes but doesn't store it yet in the buildcache.

function image_changes() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _image_changes_impl "${@}"
    )
}
# --

function _image_changes_impl() {
    local arch="$1"

    source sdk_lib/sdk_container_common.sh
    local channel=""
    channel="$(get_git_channel)"
    source ci-automation/ci_automation_common.sh
    source ci-automation/gpg_setup.sh

    source sdk_container/.repo/manifests/version.txt
    local vernum="${FLATCAR_VERSION}"

    echo "==================================================================="
    export BOARD_A="${arch}-usr"
    export FROM_A="release"
    if [ "${channel}" = "developer" ]; then
            NEW_CHANNEL="alpha"
    else
            NEW_CHANNEL="${channel}"
    fi
    NEW_CHANNEL_VERSION_A=$(curl -fsSL --retry-delay 1 --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 "https://${NEW_CHANNEL}.release.flatcar-linux.net/${BOARD_A}/current/version.txt" | grep -m 1 FLATCAR_VERSION= | cut -d = -f 2)
    MAJOR_A=$(echo "${NEW_CHANNEL_VERSION_A}" | cut -d . -f 1)
    MAJOR_B=$(echo "${FLATCAR_VERSION}" | cut -d . -f 1)
    # When the major version for the new channel is different, a transition has happened and we can find the previous release in the old channel
    if [ "${MAJOR_A}" != "${MAJOR_B}" ]; then
        case "${NEW_CHANNEL}" in
          lts)
            CHANNEL_A=stable
            ;;
          stable)
            CHANNEL_A=beta
            ;;
          *)
            CHANNEL_A=alpha
            ;;
        esac
        VERSION_A=$(curl -fsSL --retry-delay 1 --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 "https://${CHANNEL_A}.release.flatcar-linux.net/${BOARD_A}/current/version.txt" | grep -m 1 FLATCAR_VERSION= | cut -d = -f 2)
    else
        CHANNEL_A="${NEW_CHANNEL}"
        VERSION_A="${NEW_CHANNEL_VERSION_A}"
    fi
    export VERSION_A
    export CHANNEL_A
    export FROM_B="bincache"
    export VERSION_B="${vernum}"
    export BOARD_B="${arch}-usr"
    # First parts of the size-changes-report specs, the kind is
    # appended at call sites.
    SPEC_A_PART="${FROM_A}:${CHANNEL_A}:${arch}-usr:${VERSION_A}"
    SPEC_B_PART="${FROM_B}:${arch}:${VERSION_B}"
    # CHANNEL_B is unused
    echo "== Image differences compared to ${CHANNEL_A} ${VERSION_A} =="
    NEW_VERSION=$(git tag --points-at HEAD)
    cd ..
    rm -rf flatcar-build-scripts
    git clone "https://github.com/flatcar/flatcar-build-scripts"
    # Don't fail the job
    set +e
    echo "Package updates, compared to ${CHANNEL_A} ${VERSION_A}:"
    FILE=flatcar_production_image_packages.txt flatcar-build-scripts/package-diff "${VERSION_A}" "${VERSION_B}"
    echo
    echo "Image file changes, compared to ${CHANNEL_A} ${VERSION_A}:"
    FILE=flatcar_production_image_contents.txt FILESONLY=1 CUTKERNEL=1 flatcar-build-scripts/package-diff "${VERSION_A}" "${VERSION_B}"
    echo
    echo "Image kernel config changes, compared to ${CHANNEL_A} ${VERSION_A}:"
    FILE=flatcar_production_image_kernel_config.txt flatcar-build-scripts/package-diff "${VERSION_A}" "${VERSION_B}"
    echo
    echo "Image init ramdisk file changes, compared to ${CHANNEL_A} ${VERSION_A}:"
    FILE=flatcar_production_image_initrd_contents.txt FILESONLY=1 flatcar-build-scripts/package-diff "${VERSION_A}" "${VERSION_B}"
    echo
    echo "Image file size changes, compared to ${CHANNEL_A} ${VERSION_A}:"
    if ! flatcar-build-scripts/size-change-report.sh "${SPEC_A_PART}:wtd" "${SPEC_B_PART}:wtd"; then
        flatcar-build-scripts/size-change-report.sh "${SPEC_A_PART}:old" "${SPEC_B_PART}:old"
    fi
    echo
    echo "Image init ramdisk file size changes, compared to ${CHANNEL_A} ${VERSION_A}:"
    if ! flatcar-build-scripts/size-change-report.sh "${SPEC_A_PART}:initrd-wtd" "${SPEC_B_PART}:initrd-wtd"; then
        flatcar-build-scripts/size-change-report.sh "${SPEC_A_PART}:initrd-old" "${SPEC_B_PART}:initrd-old"
    fi
    echo "Take the total size difference with a grain of salt as normally initrd is compressed, so the actual difference will be smaller."
    echo "To see the actual difference in size, see if there was a report for /boot/flatcar/vmlinuz-a."
    echo "Note that vmlinuz-a also contains the kernel code, which might have changed too, so the reported difference does not accurately describe the change in initrd."
    echo
    echo "Image file size change (includes /boot, /usr and the default rootfs partitions), compared to ${CHANNEL_A} ${VERSION_A}:"
    FILE=flatcar_production_image_contents.txt CALCSIZE=1 flatcar-build-scripts/package-diff "${VERSION_A}" "${VERSION_B}"
    echo
    BASE_URL="http://${BUILDCACHE_SERVER}/images/${arch}/${vernum}"
    echo "Image URL: ${BASE_URL}/flatcar_production_image.bin.bz2"
    echo
    # Provide a python3 command for the CVE DB parsing
    export PATH="$PATH:$PWD/scripts/ci-automation/python-bin"
    # The first changelog we print is always against the previous version of the new channel (is only same as CHANNEL_A VERSION_A without a transition)
    flatcar-build-scripts/show-changes "${NEW_CHANNEL}-${NEW_CHANNEL_VERSION_A}" "${NEW_VERSION}"
    # See if a channel transition happened and print the changelog against CHANNEL_A VERSION_A which is the previous release
    if [ "${CHANNEL_A}" != "${NEW_CHANNEL}" ]; then
      flatcar-build-scripts/show-changes "${CHANNEL_A}-${VERSION_A}" "${NEW_VERSION}"
    fi
    set -e
}
# --
