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
# OUTPUT:
#
#   1. Exported container image with OS image, dev container, and related artifacts at
#        /home/sdk/image/[ARCH], torcx packages at /home/sdk/torcx
#        named "flatcar-images-[ARCH]-[FLATCAR_VERSION].tar.gz"
#        pushed to buildcache.
#   2. "./ci-cleanup.sh" with commands to clean up temporary build resources,
#        to be run after this step finishes / when this step is aborted.

set -eu

function image_build() {
    local arch="$1"

    source sdk_lib/sdk_container_common.sh
    local channel=""
    channel="$(get_git_channel)"
    source ci-automation/ci_automation_common.sh
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

    # build image and store it in the container
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
                          --torcx_root="${CONTAINER_TORCX_ROOT}" prodtar container

    # rename container and push to build cache
    docker_commit_to_buildcache "${image_container}" "${image}" "${docker_vernum}"
}
# --
