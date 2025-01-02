#!/bin/bash
#
# Copyright (c) 2024 The Flatcar Maintainers.
# Use of this source code is governed by the Apache 2.0 license.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# sbsign_image() should be called w/ the positional INPUT parameters below.

# Secure Boot image signing build automation stub.
#   This script will sign an existing OS image for Secure Boot.
#
# PREREQUISITES:
#
#   1. SDK version and OS image version are recorded in sdk_container/.repo/manifests/version.txt
#   2. Scripts repo version tag of OS image version to be built is available and checked out.
#   3. The generic Flatcar image must be present in build cache server.
#
# INPUT:
#
#   1. Architecture (ARCH) of the TARGET vm images ("arm64", "amd64").
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
#   1. OS image and related artifacts signed for Secure Boot pushed to buildcache.
#   2. If signer key was passed, signatures of artifacts from point 1, pushed along to buildcache.
#   3. DIGESTS of the artifacts from point 1, pushed to buildcache. If signer key was passed, armored ASCII files of the generated DIGESTS files too, pushed to buildcache.

function sbsign_image() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _sbsign_image_impl "${@}"
    )
}
# --

function _sbsign_image_impl() {
    local arch="$1"

    source sdk_lib/sdk_container_common.sh
    local channel=""
    channel="$(get_git_channel)"
    source ci-automation/ci_automation_common.sh
    source ci-automation/gpg_setup.sh
    source sdk_container/.repo/manifests/version.txt

    if is_official "${FLATCAR_VERSION}"; then
        export COREOS_OFFICIAL=1
    else
        export COREOS_OFFICIAL=0
    fi

    apply_local_patches

    local images_remote="images/${arch}/${FLATCAR_VERSION}"
    local images_local="__build__/images/images/${arch}-usr/${channel}-${FLATCAR_VERSION}"

    copy_from_buildcache "${images_remote}/flatcar_production_image.bin.bz2" "${images_local}"
    lbunzip2 --force "${images_local}/flatcar_production_image.bin.bz2"

    # Get SDK from either the registry or import from build cache
    # This is a NOP if the image is present locally.
    local sdk_name="flatcar-sdk-${arch}"
    local docker_sdk_vernum="$(vernum_to_docker_image_version "${FLATCAR_SDK_VERSION}")"

    docker_image_from_registry_or_buildcache "${sdk_name}" "${docker_sdk_vernum}"
    local sdk_image="$(docker_image_fullname "${sdk_name}" "${docker_sdk_vernum}")"
    echo "docker image rm -f '${sdk_image}'" >> ./ci-cleanup.sh

    local docker_vernum="$(vernum_to_docker_image_version "${FLATCAR_VERSION}")"
    local sbsign_container="flatcar-sbsign-image-${arch}-${docker_vernum}"
    ./run_sdk_container -x ./ci-cleanup.sh -n "${sbsign_container}" -v "${FLATCAR_VERSION}" -U -C "${sdk_image}" \
        ./sbsign_image --board="${arch}-usr" \
                       --group="${channel}" --version="${FLATCAR_VERSION}" \
                       --output_root="${CONTAINER_IMAGE_ROOT}" \
                       --only_store_compressed

    # Delete uncompressed generic image before signing and upload
    # Also delete update image because it will be unchanged
    rm "${images_local}"/flatcar_production_{image,update}.bin
    create_digests "${SIGNER}" "${images_local}"/*
    sign_artifacts "${SIGNER}" "${images_local}"/*
    copy_to_buildcache "${images_remote}"/ "${images_local}"/*
}
# --
