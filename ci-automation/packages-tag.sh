#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# packages_tag() should be called w/ the positional INPUT parameters below.

# build tag automation stub.
#   This script will update the versionfile with the OS packages version to build,
#    and will add a version tag (see INPUT) to the scripts repo.
#
# PREREQUISITES:
#
#   1. SDK version is recorded in sdk_container/.repo/manifests/version.txt
#   2. SDK container is either
#       - available via ghcr.io/flatcar/flatcar-sdk-[ARCH]:[VERSION] (official SDK release)
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
#
# OPTIONAL INPUT:
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
#   4. A file ../scripts.patch to apply with "git am -3" for the scripts repo.
#
#   5. A file ../overlay.patch to apply with "git am -3" for the coreos-overlay sub-module.
#
#   6. A file ../portage.patch to apply with "git am -3" for the portage-stable sub-module.
#
# OUTPUT:
#
#   1. Updated scripts repository
#        - version tag w/ submodules
#        - sdk_container/.repo/manifests/version.txt denotes new FLATCAR OS version
#   2. "./skip-build" as flag file to signal that the build should stop

function packages_tag() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _packages_tag_impl "${@}"
    )
}
# --

function _packages_tag_impl() {
    local version="$1"
    local coreos_git="${2:-}"
    local portage_git="${3:-}"

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
    if    [[ "${version}" =~ ^(stable|alpha|beta|lts)-[0-9.]+-nightly-[-0-9]+$ ]] \
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
          if [[ ret -eq 0 ]]; then
            if curl --head --fail --silent --show-error --location "https://${BUILDCACHE_SERVER}/images/amd64/${FLATCAR_VERSION}/flatcar_production_image.bin.bz2" \
              && curl --head --fail --silent --show-error --location "https://${BUILDCACHE_SERVER}/images/arm64/${FLATCAR_VERSION}/flatcar_production_image.bin.bz2"; then
                touch ./skip-build
                echo "Creating ./skip-build flag file, indicating that the build must not to continue because no new tag got created as there are no changes since tag ${existing_tag} and the Flatcar images exist" >&2
                return 0
            fi
            echo "No changes but continuing build because Flatcar images do not exist"
          elif [[ ret -eq 1 ]]; then
            echo "Found changes since last tag ${existing_tag}" >&2
          else
            echo "Error: Unexpected git diff return code (${ret})" >&2
            return 1
          fi
        fi
    fi

    # Create version file
    (
      source sdk_lib/sdk_container_common.sh
      create_versionfile "$sdk_version" "$version"
    )
    update_and_push_version "${version}" "${push_branch}"
    apply_local_patches
}
# --
