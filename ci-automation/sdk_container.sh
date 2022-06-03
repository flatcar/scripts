#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# sdk_container_build() should be called w/ the positional INPUT parameters below.

# SDK container builder automation stub.
#  This script will build an SDK container w/ board support from an SDK tarball.
#  NOTE that SDK tarball and scripts repo must have the same version or building
#  the SDK container will fail.
#
# PREREQUISITES:
#
#   1. SDK version is recorded in sdk_container/.repo/manifests/version.txt and a matching
#       SDK tarball is available on BUILDCACHE/sdk/[ARCH]/[VERSION]/flatcar-sdk-[ARCH]-[VERSION].tar.bz2
#
# OPTIONAL INPUT:

#   2. ARCH. Environment variable. Target architecture for the SDK to run on.
#        Either "amd64" or "arm64"; defaults to "amd64" if not set.
#
# OUTPUT:
#
#   1. SDK container image of the new SDK, published to buildcache.
#   2. "./ci-cleanup.sh" with commands to clean up temporary build resources,
#        to be run after this step finishes / when this step is aborted.

function sdk_container_build() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _sdk_container_build_impl "${@}"
    )
}
# --

function _sdk_container_build_impl() {
    : ${ARCH:="amd64"}

    source ci-automation/ci_automation_common.sh

    init_submodules

    source sdk_container/.repo/manifests/version.txt
    local vernum="${FLATCAR_SDK_VERSION}"
    local sdk_tarball="flatcar-sdk-${ARCH}-${vernum}.tar.bz2"

    # __build__ is in .dockerignore, so the tarball is excluded from build context
    mkdir -p __build__
    copy_from_buildcache "sdk/${ARCH}/${vernum}/${sdk_tarball}" "./__build__"


    # This will update the SDK_VERSION in versionfile
    ./build_sdk_container_image -x ./ci-cleanup.sh ./__build__/"${sdk_tarball}"

    # push artifacts to build cache
    local docker_vernum="$(vernum_to_docker_image_version "${vernum}")"
    docker_image_to_buildcache "${CONTAINER_REGISTRY}/flatcar-sdk-all" "${docker_vernum}"
    docker_image_to_buildcache "${CONTAINER_REGISTRY}/flatcar-sdk-amd64" "${docker_vernum}"
    docker_image_to_buildcache "${CONTAINER_REGISTRY}/flatcar-sdk-arm64" "${docker_vernum}"
}
# --
