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
#   3. A file ../scripts.patch to apply with "git am -3" for the scripts repo.
#
# OUTPUT:
#
#   1. OS image, dev container, related artifacts, and torcx packages pushed to buildcache.
#   2. "./ci-cleanup.sh" with commands to clean up temporary build resources,
#        to be run after this step finishes / when this step is aborted.
#   3. If signer key was passed, signatures of artifacts from point 1, pushed along to buildcache.
#   4. DIGESTS of the artifacts from point 1, pushed to buildcache. If signer key was passed, armored ASCII files of the generated DIGESTS files too, pushed to buildcache.

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

    apply_local_patches
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
    create_digests "${SIGNER}" "images/latest/"*
    sign_artifacts "${SIGNER}" "images/latest/"*
    copy_to_buildcache "images/${arch}/${vernum}/" "images/latest/"*
}
# --
