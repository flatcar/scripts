#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# sdk_bootstrap() should be called w/ the positional INPUT parameters below.

# Bootstrap SDK build automation stub.
#  This script will use a seed SDK container + tarball to bootstrap a 
#   new SDK tarball.
#
# INPUT:
#
#   1. Version of the SEED SDK to use (string).
#       The seed SDK tarball must be available on https://mirror.release.flatcar-linux.net/sdk/ ...
#       The seed SDK container must be available from https://github.com/orgs/flatcar/packages
#          (via ghcr.io/flatcar/flatcar-sdk-all:[VERSION]).
#
#   2. Version of the TARGET SDK to build (string).
#       The version pattern 'MMMM.m.p' (e.g. '3051.0.0') denotes a "official" build, i.e. a release build to be published.
#       Use any version diverging from the pattern (e.g. '3051.0.0-nightly-4302') for development / CI builds.
#       A free-standing tagged commit will be created in the scripts repo and pushed upstream.
#
# OPTIONAL INPUT:
#
#   3. ARCH. Environment variable. Target architecture for the SDK to run on.
#        Either "amd64" or "arm64"; defaults to "amd64" if not set.
#
#   4. SIGNER. Environment variable. Name of the owner of the artifact signing key.
#        Defaults to nothing if not set - in such case, artifacts will not be signed.
#        If provided, SIGNING_KEY environment variable should also be provided, otherwise this environment variable will be ignored.
#
#   5. SIGNING_KEY. Environment variable. The artifact signing key.
#        Defaults to nothing if not set - in such case, artifacts will not be signed.
#        If provided, SIGNER environment variable should also be provided, otherwise this environment variable will be ignored.
#
#   6. A file ../scripts.patch to apply with "git am -3" for the scripts repo.
#
#   7. AVOID_NIGHTLY_BUILD_SHORTCUTS. Environment variable. Tells the script to build the SDK even if nothing has changed since last nightly build.
#        See the description in ci-config.env.
#
# OUTPUT:
#
#   1. SDK tarball (gentoo catalyst output) of the new SDK, pushed to buildcache.
#   2. Updated scripts repository
#        - version tag
#        - sdk_container/.repo/manifests/version.txt denotes new SDK version
#   3. "./ci-cleanup.sh" with commands to clean up temporary build resources,
#        to be run after this step finishes / when this step is aborted.
#   4. If signer key was passed, signatures of artifacts from point 1, pushed along to buildcache.
#   5. DIGESTS of the artifacts from point 1, pushed to buildcache. If signer key was passed, armored ASCII files of the generated DIGESTS files too, pushed to buildcache.

function sdk_bootstrap() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _sdk_bootstrap_impl "${@}"
    )
}
# --

function _sdk_bootstrap_impl() {
    local seed_version=${1}
    local version=${2}
    : ${ARCH:="amd64"}

    source ci-automation/ci_automation_common.sh
    source ci-automation/gpg_setup.sh

    check_version_string "${version}"

    if [[ -n ${CIA_DEBUGTESTRUN:-} ]]; then
        set -x
    fi
    # Create new tag in scripts repo w/ updated versionfile.
    # Also push the changes to the branch ONLY IF we're doing a nightly
    #   build of the 'main' branch AND we're definitely ON the main branch.
    #   This includes intermediate SDKs when doing 2-phase nightly builds.
    local target_branch=''
    # These variables are here to make it easier to test nightly
    # builds without messing with actual release branches.
    local main_branch=${CIA_DEBUGMAINBRANCH:-main}
    local nightly=${CIA_DEBUGNIGHTLY:-nightly}
    # Matches the usual nightly tag name, optionally with an
    # intermediate suffix of the build ID too
    # (main-1234.2.3-nightly-yyyymmdd-hhmm-INTERMEDIATE).
    local nightly_pattern_1='^main-[0-9]+(\.[0-9]+){2}-'"${nightly}"'-[0-9]{8}-[0-9]{4}(-INTERMEDIATE)?$'
    local main_branch_hash=''
    if [[ ${version} =~ ${nightly_pattern_1} ]]; then
        main_branch_hash=$(git rev-parse "origin/${main_branch}")
    fi
    local -a existing_tags=()
    if [[ -n ${main_branch_hash} ]]; then
        if [[ $(git rev-parse HEAD) != "${main_branch_hash}" ]] ; then
            echo "We are doing a nightly build but we are not on top of the ${main_branch} branch. This is wrong and would result in the nightly tag not being a part of the branch." >&2
            exit 1
        fi
        target_branch=${main_branch}
        # Check for the existing tag only when we allow
        # shortcutting the builds. That way we can skip the checks
        # for build shortcutting.
        if bool_is_true "${AVOID_NIGHTLY_BUILD_SHORTCUTS}"; then
            echo "Continuing the build because AVOID_NIGHTLY_BUILD_SHORTCUTS is bool true (${AVOID_NIGHTLY_BUILD_SHORTCUTS})" >&2
        else
            git fetch --all --tags --force
            # exit code is always 0, output may be empty
            mapfile -t existing_tags < <(git tag --points-at HEAD)
        fi
    fi
    local nightly_pattern_2='^main-[0-9]+(\.[0-9]+){2}-'"${nightly}"'-[0-9]{8}-[0-9]{4}$'
    local tag nightly_tag=''
    for tag in "${existing_tags[@]}"; do
        if [[ ${tag} =~ ${nightly_pattern_2} ]]; then
            nightly_tag=${tag}
            break
        fi
    done
    # If the found tag is a nightly tag, we stop this build if there
    # are no changes and the relevant images can be found in the
    # bincache.
    if [[ -n ${nightly_tag} ]]; then
        local -i ret=0
        git diff --exit-code --quiet "${nightly_tag}" || ret=$?
        if [[ ret -eq 0 ]]; then
            local -a versions=(
                $(
                    source sdk_lib/sdk_container_common.sh
                    source "${sdk_container_common_versionfile}"
                    echo "${FLATCAR_SDK_VERSION}"
                    echo "${FLATCAR_VERSION}"
                )
            )
            local flatcar_sdk_version=${versions[0]}
            local flatcar_version=${versions[1]}
            local sdk_docker_vernum=""
            sdk_docker_vernum=$(vernum_to_docker_image_version "${flatcar_sdk_version}")
            if check_bincache_images_existence \
                   "https://${BUILDCACHE_SERVER}/containers/${sdk_docker_vernum}/flatcar-sdk-all-${sdk_docker_vernum}.tar.zst" \
                   "https://${BUILDCACHE_SERVER}/images/amd64/${flatcar_version}/flatcar_production_image.bin.bz2" \
                   "https://${BUILDCACHE_SERVER}/images/arm64/${flatcar_version}/flatcar_production_image.bin.bz2"; then
                echo "Stopping build because there are no changes since tag ${nightly_tag}, the SDK container tar ball and the Flatcar images exist" >&2
                return 0
            fi
            echo "No changes but continuing build because SDK container tar ball and/or the Flatcar images do not exist" >&2
        elif [[ ret -eq 1 ]]; then
            echo "HEAD is tagged with a nightly tag and yet there a differences? This is fishy and needs to be investigated. Maybe you forgot to commit your changes?" >&2
            exit 1
        else
            echo "Error: Unexpected git diff return code (${ret})" >&2
            return 1
        fi
    fi
    if [[ -n ${CIA_DEBUGTESTRUN:-} ]]; then
        set +x
    fi

    local vernum=${version#*-} # remove alpha-,beta-,stable-,lts- version tag
    local git_vernum=${vernum}

    # Update FLATCAR_VERSION[_ID], BUILD_ID, and SDK in versionfile
    (
        source sdk_lib/sdk_container_common.sh
        create_versionfile "${vernum}"
    )
    if [[ -n ${CIA_DEBUGTESTRUN:-} ]]; then
        set -x
    fi
    update_and_push_version "${version}" "${target_branch}"
    if [[ -n ${CIA_DEBUGTESTRUN:-} ]]; then
        exit 0
    fi
    apply_local_patches

    local failed=''
    local logdir='__build__/sdk-bootstrap-logs-to-upload/'
    mkdir -p "${logdir}"
    ./bootstrap_sdk_container -l "${logdir}" -x ./ci-cleanup.sh "${seed_version}" "${vernum}" || failed=x

    # push SDK tarball to buildcache
    # Get Flatcar version number format (separator is '+' instead of '-',
    # equal to $(strip_version_prefix "$version")
    source sdk_container/.repo/manifests/version.txt
    local dest_tarball="flatcar-sdk-${ARCH}-${FLATCAR_SDK_VERSION}.tar.bz2"
    local logs_tarball="sdk-bootstrap-logs-${ARCH}-$(date --utc '+%F-%H%M-%S').tar.xz"

    # change the owner of the files and directories in __build__ back
    # to ourselves, otherwise we could fail to sign the artifacts as
    # we lacked write permissions in the directory of the signed
    # artifact
    local uid
    local gid
    uid=$(id --user)
    gid=$(id --group)
    sudo chown --recursive "${uid}:${gid}" __build__
    if [[ -z ${failed} ]]; then
        (
            cd "__build__/images/catalyst/builds/flatcar-sdk"
            create_digests "${SIGNER}" "${dest_tarball}"
            sign_artifacts "${SIGNER}" "${dest_tarball}"*
            copy_to_buildcache "sdk/${ARCH}/${FLATCAR_SDK_VERSION}" "${dest_tarball}"*
        )
    fi

    # collect logs
    local catalyst_log='__build__/images/catalyst/log/flatcar-sdk'
    if dir_contains_globs "${catalyst_log}" 'stage*'; then
        cp -a "${catalyst_log}/stage"* "${logdir}"
    fi
    mkdir -p "${logdir}/config-logs"
    # TODO: Add more interesting files (meson logs, cmake logs)
    local -a interesting_files=( config.log ) find_flags=()
    for f in "${interesting_files[@]}"; do
        if [[ ${#find_flags[@]} -ne 0 ]]; then
            find_flags+=( '-o' )
        fi
        find_flags+=( '-name' "${f}" )
    done
    local catalyst_tmp='__build__/images/catalyst/tmp/flatcar-sdk'
    local -a logs
    local l d
    mapfile -t logs < <(find "${catalyst_tmp}" "${find_flags[@]}")
    for l in "${logs[@]}"; do
        d=${l#"${catalyst_tmp}"}
        d=${d#/}
        if [[ ${d} = */* ]]; then
            d=${d%/*}
            mkdir -p "${logdir}/config-logs/${d}"
        else
            d='.'
        fi
        cp -a "${l}" "${logdir}/config-logs/${d}"
    done
    if dir_contains_globs "${logdir}" '*'; then
        (
            cd "${logdir}"
            tar -cJf "${logs_tarball}" *
            create_digests "${SIGNER}" "${logs_tarball}"
            sign_artifacts "${SIGNER}" "${logs_tarball}"*
            copy_to_buildcache "build-logs/${FLATCAR_SDK_VERSION}" "${logs_tarball}"*
        )
    fi
    upload_fail_logs
    if [[ -n ${failed} ]]; then exit 1; fi
}
# --
