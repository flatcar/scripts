#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# sdk_container_update() should be called w/ the positional INPUT parameters below.

# SDK container update automation stub.
#  This script will create a new SDK container image based on an existing container image.
#  It is meant to be used for updating tools in the SDK that do not directly affect OS image
#  generation - like e.g. the mantle suite tools (kola, ore, etc.).
#
# PREREQUISITES:
#
#   1. SDK version is recorded in sdk_container/.repo/manifests/version.txt and a matching source
#       SDK container is available on build cache at "/containers/[VERSION]/flatcar-sdk-all-[VERSION].tar.gz"
#         (nightly / dev builds)
#      OR
#       SDK image is available on ghcr.io/flatcar-linux/flatcar-sdk-all:[VERSION]
#         (official SDK releases)
#      Specifically, the "-all" version of the source SDK image is required.
#
# OPTIONAL INPUT
#
#   1. Target SDK version number (without alpha-/beta-/etc. prefix).
#      If not provided it will be computed from the source SDK, and the patch level is bumped
#      (e.g. 3139.0.0 => 3139.0.1).
#
#   2. coreos-overlay repository tag to use (commit-ish).
#       Optional - use scripts repo sub-modules as-is if not set.
#       This version will be checked out / pulled from remote in the coreos-overlay git submodule.
#       The submodule config will be updated to point to this version before the TARGET SDK tag is created and pushed.
#
#   3. portage-stable repository tag to use (commit-ish).
#       Optional - use scripts repo sub-modules as-is if not set.
#       This version will be checked out / pulled from remote in the portage-stable git submodule.
#       The submodule config will be updated to point to this version before the TARGET SDK tag is created and pushed.
#
# OUTPUT:
#
#   1. SDK container image of the new SDK, published to buildcache
#       at "/containers/[NEW_VERSION]/flatcar-sdk-all-[NEW_VERSION].tar.gz"
#
#   2. New SDK version tagged in scripts and tag pushed to origin.
#
#   3. "./ci-cleanup.sh" with commands to clean up temporary build resources,
#        to be run after this step finishes / when this step is aborted.

set -euo pipefail

# Helper function to generate a new version from the current SDK version
#  in version.txt.
# Can also be used by CI automation to generate "$1" for sdk_container_update
#  coreos_git and portage_git are to be provided.
#
function sdk_container_update_generate_new_version() {
    source ci-automation/ci_automation_common.sh
    source sdk_container/.repo/manifests/version.txt

    local current_vernum="${FLATCAR_SDK_VERSION}"

    local current_major_minor="$(echo "${current_vernum}" | sed 's/^\([0-9]\+\.[0-9]\+\).*/\1/')"
    local current_patchlevel="$(echo "${current_vernum}" | sed 's/^[0-9]\+\.[0-9]\+\.\([0-9]\+\).*/\1/')"
    local current_suffix="$(echo "${current_vernum}" | sed 's/^\([0-9]\+\.[0-9]\+\.[0-9]\+\)//')"

    current_patchlevel="$((current_patchlevel + 1))"
    echo "${current_major_minor}.${current_patchlevel}${current_suffix}"
}
# --

function sdk_container_update() {
    local vernum="${1:-}"
    local coreos_git="${2:-}"
    local portage_git="${3:-}"

    source ci-automation/ci_automation_common.sh
    init_submodules

    # Make sure source SDK is present for `update_sdk_container_image`
    source sdk_container/.repo/manifests/version.txt
    local source_docker_vernum="$(vernum_to_docker_image_version "${FLATCAR_SDK_VERSION}")"
    docker_image_from_registry_or_buildcache "flatcar-sdk-all" "${source_docker_vernum}"
    local source_sdk_image="$(docker_image_fullname "flatcar-sdk-all" "${source_docker_vernum}")"
    echo "docker image rm -f '${source_sdk_image}'" >> ./ci-cleanup.sh

    if [ -n "${coreos_git}" ] ; then
        update_submodule "coreos-overlay" "${coreos_git}"
    fi
    if [ -n "${portage_git}" ] ; then
        update_submodule "portage-stable" "${portage_git}"
    fi

    if [ -z "${vernum}" ] ; then
        vernum="$(sdk_container_update_generate_new_version)"
    fi

    ./update_sdk_container_image -x ./ci-cleanup.sh "${vernum}"

    local docker_vernum="$(vernum_to_docker_image_version "${vernum}")"
    docker_image_to_buildcache "${CONTAINER_REGISTRY}/flatcar-sdk-all" "${docker_vernum}"
    docker_image_to_buildcache "${CONTAINER_REGISTRY}/flatcar-sdk-amd64" "${docker_vernum}"
    docker_image_to_buildcache "${CONTAINER_REGISTRY}/flatcar-sdk-arm64" "${docker_vernum}"

    update_and_push_version "sdk-${vernum}"
}
# --
