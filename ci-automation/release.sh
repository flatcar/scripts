#!/bin/bash

# Copyright (c) 2022 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# release_build() is currently called with no positional INPUT parameters but uses the signing env vars.

# Release build automation stub.
#   This script will release the image build from bincache to the cloud offers.
#
# PREREQUISITES:
#
#   1. SDK version and OS image version are recorded in sdk_container/.repo/manifests/version.txt
#   2. Scripts repo version tag of OS image version to be built is available and checked out.
#   3. Mantle container docker image reference is stored in sdk_container/.repo/manifests/mantle-container.
#   4. Vendor image and torcx docker tarball + manifest to run tests for are available on buildcache
#         ( images/[ARCH]/[FLATCAR_VERSION]/ )
#   5. SDK container is either
#       - available via ghcr.io/flatcar-linux/flatcar-sdk-[ARCH]:[VERSION] (official SDK release)
#       OR
#       - available via build cache server "/containers/[VERSION]/flatcar-sdk-[ARCH]-[VERSION].tar.gz"
#         (dev SDK)
#
# INPUT:
#
#   (none)
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
#   1. The cloud images are published with mantle's plume and ore tools
#   2. The AWS AMI text files are pushed to buildcache ( images/[ARCH]/[FLATCAR_VERSION]/ )
#   3. "./ci-cleanup.sh" with commands to clean up temporary build resources,
#        to be run after this step finishes / when this step is aborted.
#   4. If signer key was passed, signatures of artifacts from point 1, pushed along to buildcache.
#   5. DIGESTS of the artifacts from point 1, pushed to buildcache. If signer key was passed, armored ASCII files of the generated DIGESTS files too, pushed to buildcache.

function release_build() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _release_build_impl "${@}"
    )
}

function _inside_mantle() {
  # Run a subshell for the same reasons as above
  (
    set -euo pipefail

    source ci-automation/ci_automation_common.sh
    source sdk_container/.repo/manifests/version.txt

    # TODO: set up credentials
    # TODO: run mantle pre-release and release for all platforms
    # (needs changes in mantle to consume from buildcache via https)
    # TODO: run ore for AWS marketplace upload
  )
}

function _release_build_impl() {
    source ci-automation/ci_automation_common.sh
    source ci-automation/gpg_setup.sh
    init_submodules

    source sdk_container/.repo/manifests/version.txt
    local sdk_version="${FLATCAR_SDK_VERSION}"
    local docker_sdk_vernum="$(vernum_to_docker_image_version "${sdk_version}")"
    local vernum="${FLATCAR_VERSION}"
    local docker_vernum="$(vernum_to_docker_image_version "${vernum}")"

    local container_name="flatcar-publish-${docker_vernum}"
    local mantle_ref
    mantle_ref=$(cat sdk_container/.repo/manifests/mantle-container)
    # A job on each worker prunes old mantle images (docker image prune), no need to do it here
    echo "docker rm -f '${container_name}'" >> ./ci-cleanup.sh

    touch sdk_container/.env # This file should already contain the required credentials as env vars
    docker run --pull always --rm --name="${container_name}" --net host \
      -w /work -v "$PWD":/work "${mantle_ref}" bash -c "source ci-automation/release.sh; _inside_mantle"
    # TODO: sign and copy resulting AMI text file to buildcache
    # TODO: run CF template update
    # TODO: publish SDK container image if not published yet (i.e., on new majors)
    echo "===="
    echo "Done, now you can copy the images to Origin"
    echo "===="
    # Future: trigger copy to Origin in a secure way
    # Future: trigger update payload signing
    # Future: trigger website update
    # Future: trigger release email sending
    # Future: trigger push to nebraska
    # Future: trigger Origin symlink switch
}
