#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# image_build() should be called w/ the positional INPUT parameters below.

# Binary OS image build automation stub.
#   This script will build the OS image from a pre-built packages container.
#
# PREREQUISITES:
#
#   1. SDK version and OS image version are recorded in sdk_container/.repo/manifests/version.txt
#   2. Scripts repo version tag of OS image version to be built is available and checked out.
#   3. Flatcar packages container is available via build cache server
#       from "/containers/[VERSION]/flatcar-packages-[ARCH]-[FLATCAR_VERSION].tar.gz"
#       or present locally. Container must contain binary packages and torcx artefacts.
#
# INPUT:
#
#   1. Architecture (ARCH) of the TARGET OS image ("arm64", "amd64").
#
# OPTIONAL INPUT:
#
#   1. SIGNER. Environment variable. Name of the owner of the artifact signing key.
#        Defaults to nothing if not set - in such case, artifacts will not be signed.
#        If provided, SIGNING_KEY environment variable should also be provided, otherwise this environment variable will be ignored.
#
#   2. SIGNING_KEY. Environment variable. The artifact signing key.
#        Defaults to nothing if not set - in such case, artifacts will not be signed.
#        If provided, SIGNER environment variable should also be provided, otherwise this environment variable will be ignored.
#
# OUTPUT:
#
#   1. OS image, dev container, related artifacts, and torcx packages pushed to buildcache.
#   2. "./ci-cleanup.sh" with commands to clean up temporary build resources,
#        to be run after this step finishes / when this step is aborted.
#   3. If signer key was passed, signatures of artifacts from point 1, pushed along to buildcache.

function image_build() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _image_build_impl "${@}"
    )
}
# --

function _image_build_impl() {
    local arch="$1"

    source sdk_lib/sdk_container_common.sh
    local channel=""
    channel="$(get_git_channel)"
    source ci-automation/ci_automation_common.sh
    source ci-automation/gpg_setup.sh
    init_submodules

    source sdk_container/.repo/manifests/version.txt
    local vernum="${FLATCAR_VERSION}"
    local docker_vernum="$(vernum_to_docker_image_version "${vernum}")"

    local packages="flatcar-packages-${arch}"
    local packages_image="${packages}:${docker_vernum}"

    docker_image_from_buildcache "${packages}" "${docker_vernum}"

    local image="flatcar-images-${arch}"
    local image_container="${image}-${docker_vernum}"

    local official_arg=""
    if is_official "${vernum}"; then
            export COREOS_OFFICIAL=1
            official_arg="--official"
    else
            export COREOS_OFFICIAL=0
            official_arg="--noofficial"
    fi

    # build image and related artifacts
    ./run_sdk_container -x ./ci-cleanup.sh -n "${image_container}" -C "${packages_image}" \
            -v "${vernum}" \
            mkdir -p "${CONTAINER_IMAGE_ROOT}"
    ./run_sdk_container -n "${image_container}" -C "${packages_image}" \
            -v "${vernum}" \
            ./set_official --board="${arch}-usr" "${official_arg}"
    ./run_sdk_container -n "${image_container}" -C "${packages_image}" \
            -v "${vernum}" \
            ./build_image --board="${arch}-usr" --group="${channel}" \
                          --output_root="${CONTAINER_IMAGE_ROOT}" \
                          --only_store_compressed \
                          --torcx_root="${CONTAINER_TORCX_ROOT}" prodtar container

    # copy resulting images + push to buildcache
    local images_out="images/"
    rm -rf "${images_out}"
    ./run_sdk_container -n "${image_container}" -C "${packages_image}" \
            -v "${vernum}" \
            mv "${CONTAINER_IMAGE_ROOT}/${arch}-usr/" "./${images_out}/"

    # Delete uncompressed generic image before signing and upload
    rm "images/latest/flatcar_production_image.bin" "images/latest/flatcar_production_update.bin"
    sign_artifacts "${SIGNER}" "images/latest/"*
    copy_to_buildcache "images/${arch}/${vernum}/" "images/latest/"*

    (
    set +x
    # Don't fail the whole job
    set +e
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
    export FROM_B="file://${PWD}/images/latest"
    # Use the directory directly (and BOARD_B and CHANNEL_B are unused)
    export VERSION_B="."
    echo "== Image differences compared to ${CHANNEL_A} ${VERSION_A} =="
    NEW_VERSION=$(git tag --points-at HEAD)
    cd ..
    rm -rf flatcar-build-scripts
    git clone "https://github.com/flatcar-linux/flatcar-build-scripts"
    echo "Package updates, compared to ${CHANNEL_A} ${VERSION_A}:"
    FILE=flatcar_production_image_packages.txt flatcar-build-scripts/package-diff "${VERSION_A}" "${VERSION_B}"
    echo
    echo "Image file changes, compared to ${CHANNEL_A} ${VERSION_A}:"
    FILE=flatcar_production_image_contents.txt FILESONLY=1 CUTKERNEL=1 flatcar-build-scripts/package-diff "${VERSION_A}" "${VERSION_B}"
    echo
    echo "Image kernel config changes, compared to ${CHANNEL_A} ${VERSION_A}:"
    FILE=flatcar_production_image_kernel_config.txt flatcar-build-scripts/package-diff "${VERSION_A}" "${VERSION_B}"
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
    )
}
# --
