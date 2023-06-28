#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# packages_build() should be called w/ the positional INPUT parameters below.

# OS image binary packages build automation stub.
#   This script will use an SDK container to build packages for an OS image.
#
# PREREQUISITES:
#
#   1. SDK version and OS image version are recorded in sdk_container/.repo/manifests/version.txt
#   2. Scripts repo version tag of OS image version to be built is available and checked out.
#   3. SDK container is either
#       - available via ghcr.io/flatcar/flatcar-sdk-[ARCH]:[VERSION] (official SDK release)
#       OR
#       - available via build cache server "/containers/[VERSION]/flatcar-sdk-[ARCH]-[VERSION].tar.gz"
#         (dev SDK)
#
# INPUT:
#
#   1. Architecture (ARCH) of the TARGET OS image ("arm64", "amd64").
#
#
# OPTIONAL INPUT:
#
#   2. SIGNER. Environment variable. Name of the owner of the artifact signing key.
#        Defaults to nothing if not set - in such case, artifacts will not be signed.
#        If provided, SIGNING_KEY environment variable should also be provided, otherwise this environment variable will be ignored.
#
#   3. SIGNING_KEY. Environment variable. The artifact signing key.
#        Defaults to nothing if not set - in such case, artifacts will not be signed.
#        If provided, SIGNER environment variable should also be provided, otherwise this environment variable will be ignored.
#
#   4. A file ../scripts.patch to apply with "git am -3" for the scripts repo.
#
# OUTPUT:
#
#   1. Exported container image "flatcar-packages-[ARCH]-[VERSION].tar.gz" with binary packages
#       pushed to buildcache, and torcx_manifest.json pushed to "images/${arch}/${vernum}/"
#       (for use with tests).
#   2. "./ci-cleanup.sh" with commands to clean up temporary build resources,
#        to be run after this step finishes / when this step is aborted.
#   3. If signer key was passed, signatures of artifacts from point 1, pushed along to buildcache.
#   4. DIGESTS of the artifacts from point 1, pushed to buildcache. If signer key was passed, armored ASCII files of the generated DIGESTS files too, pushed to buildcache.

function packages_build() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _packages_build_impl "${@}"
    )
}
# --

function _packages_build_impl() {
    local arch="$1"

    source ci-automation/ci_automation_common.sh
    source ci-automation/gpg_setup.sh

    source sdk_container/.repo/manifests/version.txt
    local sdk_version="${FLATCAR_SDK_VERSION}"

    # Get SDK from either the registry or import from build cache
    # This is a NOP if the image is present locally.
    local sdk_name="flatcar-sdk-${arch}"
    local docker_sdk_vernum="$(vernum_to_docker_image_version "${sdk_version}")"

    docker_image_from_registry_or_buildcache "${sdk_name}" "${docker_sdk_vernum}"
    local sdk_image="$(docker_image_fullname "${sdk_name}" "${docker_sdk_vernum}")"
    echo "docker image rm -f '${sdk_image}'" >> ./ci-cleanup.sh

    # Set name of the packages container for later rename / export
    local vernum="${FLATCAR_VERSION}"
    local docker_vernum="$(vernum_to_docker_image_version "${vernum}")"
    local packages_container="flatcar-packages-${arch}-${docker_vernum}"
    local torcx_pkg_url="https://${BUILDCACHE_SERVER}/images/${arch}/${vernum}/torcx"

    source sdk_lib/sdk_container_common.sh

    if is_official "${vernum}"; then
        # A channel returned by get_git_channel should not ever be
        # "developer" here, because it's an official build done from
        # one of the maintenance branches. So if the channel happens
        # to be "developer", then you are doing it wrong (releasing
        # from the main branch?).
        torcx_pkg_url="https://$(get_git_channel).release.flatcar-linux.net/${arch}-usr/${vernum}/torcx"
    fi

    apply_local_patches
    # Build packages; store packages and torcx output in container
    ./run_sdk_container -x ./ci-cleanup.sh -n "${packages_container}" -v "${vernum}" \
        -C "${sdk_image}" \
        mkdir -p "${CONTAINER_TORCX_ROOT}"
    ./run_sdk_container -n "${packages_container}" -v "${vernum}" \
        -C "${sdk_image}" \
        ./build_packages --board="${arch}-usr" \
            --torcx_output_root="${CONTAINER_TORCX_ROOT}" \
            --torcx_extra_pkg_url="${torcx_pkg_url}"

    # copy torcx manifest and docker tarball for publishing
    local torcx_tmp="__build__/torcx_tmp"
    rm -rf "${torcx_tmp}"
    mkdir "${torcx_tmp}"
    ./run_sdk_container -n "${packages_container}" -v "${vernum}" \
        -C "${sdk_image}" \
        cp -r "${CONTAINER_TORCX_ROOT}/" \
        "${torcx_tmp}"

    # run_sdk_container updates the version file, use that version from here on
    source sdk_container/.repo/manifests/version.txt
    local vernum="${FLATCAR_VERSION}"
    local docker_vernum="$(vernum_to_docker_image_version "${vernum}")"
    local packages_image="flatcar-packages-${arch}"

    # generate image + push to build cache
    docker_commit_to_buildcache "${packages_container}" "${packages_image}" "${docker_vernum}"

    # publish torcx output root for consumption by build_image
    local torcx_root_tar="torcx_root.tar.zst"
    tar --zstd -cpf "${torcx_root_tar}" -C "${torcx_tmp}/torcx" .
    copy_to_buildcache "images/${arch}/${vernum}/torcx" "${torcx_root_tar}"

    # Publish torcx manifest and docker tarball to "images" cache so tests can pull it later.
    create_digests "${SIGNER}" \
        "${torcx_tmp}/torcx/${arch}-usr/latest/torcx_manifest.json" \
        "${torcx_tmp}/torcx/pkgs/${arch}-usr/docker/"*/*.torcx.tgz
    sign_artifacts "${SIGNER}" \
        "${torcx_tmp}/torcx/${arch}-usr/latest/torcx_manifest.json"* \
        "${torcx_tmp}/torcx/pkgs/${arch}-usr/docker/"*/*.torcx.tgz*
    copy_to_buildcache "images/${arch}/${vernum}/torcx" \
        "${torcx_tmp}/torcx/${arch}-usr/latest/torcx_manifest.json"*
    copy_to_buildcache "images/${arch}/${vernum}/torcx" \
        "${torcx_tmp}/torcx/pkgs/${arch}-usr/docker/"*/*.torcx.tgz*
}
# --
