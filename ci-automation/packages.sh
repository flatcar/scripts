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
#   It will update the versionfile with the OS packages version built,
#    and will add a version tag (see INPUT) to the scripts repo. 
#
# PREREQUISITES:
#
#   1. SDK version is recorded in sdk_container/.repo/manifests/version.txt
#   2. SDK container is either
#       - available via ghcr.io/flatcar-linux/flatcar-sdk-[ARCH]:[VERSION] (official SDK release)
#       OR
#       - available via build cache server "/containers/[VERSION]/flatcar-sdk-[ARCH]-[VERSION].tar.gz"
#         (dev SDK)
#
# INPUT:
#
#   1. Version of the TARGET OS image to build (string).
#       The version pattern '(alpha|beta|stable|lts)-MMMM.m.p' (e.g. 'alpha-3051.0.0')
#         denotes a "official" build, i.e. a release build to be published.
#       Use any version diverging from the pattern (e.g. 'alpha-3051.0.0-nightly-4302') for development / CI builds.
#       A tag of this version will be created in the scripts repo and pushed upstream.
#
#   2. Architecture (ARCH) of the TARGET OS image ("arm64", "amd64").
#
#
# OPTIONAL INPUT:
#
#   3. coreos-overlay repository tag to use (commit-ish).
#       Optional - use scripts repo sub-modules as-is if not set.
#       This version will be checked out / pulled from remote in the coreos-overlay git submodule.
#       The submodule config will be updated to point to this version before the TARGET SDK tag is created and pushed.
#
#   4. portage-stable repository tag to use (commit-ish).
#       Optional - use scripts repo sub-modules as-is if not set.
#       This version will be checked out / pulled from remote in the portage-stable git submodule.
#       The submodule config will be updated to point to this version before the TARGET SDK tag is created and pushed.
#
#   5. SIGNER. Environment variable. Name of the owner of the artifact signing key.
#        Defaults to nothing if not set - in such case, artifacts will not be signed.
#        If provided, SIGNING_KEY environment variable should also be provided, otherwise this environment variable will be ignored.
#
#   6. SIGNING_KEY. Environment variable. The artifact signing key.
#        Defaults to nothing if not set - in such case, artifacts will not be signed.
#        If provided, SIGNER environment variable should also be provided, otherwise this environment variable will be ignored.
#
# OUTPUT:
#
#   1. Exported container image "flatcar-packages-[ARCH]-[VERSION].tar.gz" with binary packages
#       pushed to buildcache, and torcx_manifest.json pushed to "images/${arch}/${vernum}/"
#       (for use with tests).
#   2. Updated scripts repository
#        - version tag w/ submodules
#        - sdk_container/.repo/manifests/version.txt denotes new FLATCAR OS version
#   3. "./ci-cleanup.sh" with commands to clean up temporary build resources,
#        to be run after this step finishes / when this step is aborted.
#   4. If signer key was passed, signatures of artifacts from point 1, pushed along to buildcache.

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
    local version="$1"
    local arch="$2"
    local coreos_git="${3:-}"
    local portage_git="${4:-}"

    source ci-automation/ci_automation_common.sh
    source ci-automation/gpg_setup.sh
    init_submodules

    check_version_string "${version}"

    source sdk_container/.repo/manifests/version.txt
    local sdk_version="${FLATCAR_SDK_VERSION}"

    if [ -n "${coreos_git}" ] ; then
        update_submodule "coreos-overlay" "${coreos_git}"
    fi
    if [ -n "${portage_git}" ] ; then
        update_submodule "portage-stable" "${portage_git}"
    fi

    # Create new tag in scripts repo w/ updated versionfile + submodules.
    # Also push the changes to the branch ONLY IF we're doing a nightly
    #   build of the 'main'/'flatcar-MAJOR' branch AND we're definitely ON the respective branch
    #   (`scripts` and submodules).
    local push_branch="false"
    if   [[ "${version}" =~ ^(stable|alpha|beta|lts)-[0-9.]+-nightly-[-0-9]+$ ]] \
       && [[ "$(git rev-parse --abbrev-ref HEAD)" =~ ^flatcar-[0-9]+$ ]] \
       && [[ "$(git -C sdk_container/src/third_party/coreos-overlay/ rev-parse --abbrev-ref HEAD)" =~ ^flatcar-[0-9]+$ ]] \
       && [[ "$(git -C sdk_container/src/third_party/portage-stable/ rev-parse --abbrev-ref HEAD)" =~ ^flatcar-[0-9]+$ ]] ; then
        push_branch="true"
        local existing_tag=""
        existing_tag=$(git tag --points-at HEAD) # exit code is always 0, output may be empty
        # If the found tag is a release or nightly tag, we stop this build if there are no changes
        if [[ "${existing_tag}" =~ ^(stable|alpha|beta|lts)-[0-9.]+(|-nightly-[-0-9]+)$ ]]; then
          local ret=0
          git diff --exit-code "${existing_tag}" || ret=$?
          if [ "$ret" = "0" ]; then
            echo "Stopping build because there are no changes since tag ${existing_tag}" >&2
            return 0
          elif [ "$ret" = "1" ]; then
            echo "Found changes since last tag ${existing_tag}" >&2
          else
            echo "Error: Unexpected git diff return code (${ret})" >&2
            return 1
          fi
        fi
    fi

    # Get SDK from either the registry or import from build cache
    # This is a NOP if the image is present locally.
    local sdk_name="flatcar-sdk-${arch}"
    local docker_sdk_vernum="$(vernum_to_docker_image_version "${sdk_version}")"

    docker_image_from_registry_or_buildcache "${sdk_name}" "${docker_sdk_vernum}"
    local sdk_image="$(docker_image_fullname "${sdk_name}" "${docker_sdk_vernum}")"
    echo "docker image rm -f '${sdk_image}'" >> ./ci-cleanup.sh

    # Set name of the packages container for later rename / export
    local vernum="${version#*-}" # remove main-,alpha-,beta-,stable-,lts- version tag
    local docker_vernum="$(vernum_to_docker_image_version "${vernum}")"
    local packages_container="flatcar-packages-${arch}-${docker_vernum}"

    # Create version file
    (
      source sdk_lib/sdk_container_common.sh
      create_versionfile "$sdk_version" "$version"
    )
    update_and_push_version "${version}" "${push_branch}"

    # Build packages; store packages and torcx output in container
    ./run_sdk_container -x ./ci-cleanup.sh -n "${packages_container}" -v "${version}" \
        -C "${sdk_image}" \
        mkdir -p "${CONTAINER_TORCX_ROOT}"
    ./run_sdk_container -n "${packages_container}" -v "${version}" \
        -C "${sdk_image}" \
        ./build_packages --board="${arch}-usr" \
            --torcx_output_root="${CONTAINER_TORCX_ROOT}"

    # copy torcx manifest and docker tarball for publishing
    local torcx_tmp="__build__/torcx_tmp"
    rm -rf "${torcx_tmp}"
    mkdir "${torcx_tmp}"
    ./run_sdk_container -n "${packages_container}" -v "${version}" \
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

    # Publish torcx manifest and docker tarball to "images" cache so tests can pull it later.
    sign_artifacts "${SIGNER}" \
        "${torcx_tmp}/torcx/${arch}-usr/latest/torcx_manifest.json" \
        "${torcx_tmp}/torcx/pkgs/${arch}-usr/docker/"*/*.torcx.tgz
    copy_to_buildcache "images/${arch}/${vernum}/torcx" \
        "${torcx_tmp}/torcx/${arch}-usr/latest/torcx_manifest.json"*
    copy_to_buildcache "images/${arch}/${vernum}/torcx" \
        "${torcx_tmp}/torcx/pkgs/${arch}-usr/docker/"*/*.torcx.tgz*
}
# --
