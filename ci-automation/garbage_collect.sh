#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# garbage_collect() should be called after sourcing.
#
# The garbage collector will remove artifacts of all NON-RELEASE versions from the build cache
# which BOTH
#   * exceed the number of builds to keep (defaults to 50)
#   AND
#   * are older than the minimum purge age (14 days by default)
#
# Note that the min age threshold can lead to MORE than 50 builds being kept if this script
#   is run with its default values.
#
# Additionally, the garbage collector will remove all artifacts and directories that do not have
# a version TAG in the scripts repository.
#
#  OPTIONAL INPUT
#  - Number of (recent) versions to keep. Defaults to 50.
#           Explicitly setting this value will reset the minimum age (see below) to 0 days.
#  - Minimum age of version tag to be purged, in days. Defaults to 14.
#           Only artifacts older than this AND exceeding the builds to keep threshold
#           will be removed.
#  - PURGE_VERSIONS (Env variable). Space-separated list of versions to purge
#            instead of all but the 50 most recent ones.
#            Setting this will IGNORE minimum age and number of versions to keep.
#            NOTE that only dev versions (not official releases) may be specified.
#            This is to prevent accidental deletion of official release tags from the git repo.
#  - DRY_RUN (Env variable). Set to "y" to just list what would be done but not
#            actually purge anything.

# Flatcar CI automation garbage collector.
#  This script removes development (non-official) build artifacts:
#   - SDK tarballs, build step containers, and vendor images on buildcache
#   - SDK containers built via Github actions (e.g. from PRs).
#      See https://github.com/flatcar/scripts/blob/main/.github/workflows/update-sdk.yaml
#   - tags from the scripts repository
#
#  Garbage collection is based on development (non-official) version tags
#   in the scripts repo. The newest 50 builds will be retained,
#   all older builds will be purged (50 is the default, see OPTIONAL INPUT above).

function garbage_collect() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _garbage_collect_impl "${@}"
    )
}
# --

function _garbage_collect_impl() {
    local keep="${1:-}"
    local min_age_days="${2:-}"
    local dry_run="${DRY_RUN:-}"
    local purge_versions="${PURGE_VERSIONS:-}"

    # Set defaults; user-provided 'keep' has priority over default 'min_age_days'
    if [ -n "${keep}" -a -z "${min_age_days}" ] ; then
        min_age_days="0"
    elif [ -z "${keep}" ] ; then
        keep="50"
    fi
    if [ -z "${min_age_days}" ] ; then
        min_age_days="14"
    fi

    local min_age_date="$(date -d "${min_age_days} days ago" +'%Y-%m-%d')"
    echo "######## Garbage collector starting ########"
    echo
    if [ -z "${purge_versions}" ] ; then
        echo "Number of versions to keep: '${keep}'"
        echo "Keep newer than: '${min_age_date}' (overrides number of versions to keep)"
    fi
    echo

    if [ -z "${purge_versions}" ] ; then
        # Generate a list "<timestamp> | <tagname>" from all repo tags that look like dev versions
        local versions_detected="$(git tag -l --sort=-committerdate \
                                          --format="%(creatordate:format:%Y-%m-%d) | %(refname:strip=2)" \
                | grep -E '.*\| (main|alpha|beta|stable|lts)-[0-9]+\.[0-9]+\.[0-9]+-.*' \
                | grep -vE '(-pro)$')"

        echo "######## Full list of version(s) and their creation dates ########"
        echo
        echo "${versions_detected}" | awk '{printf "%5d %s\n", NR, $0}'

        # Filter minimum number of versions to keep, min age
        purge_versions="$(echo "${versions_detected}" \
                            | awk -v keep="${keep}" -v min_age="${min_age_date}" '{
                                if (keep > 0) {
                                    keep = keep - 1
                                    next
                                }

                                if ($1 > min_age)
                                    next

                                print $3
                                }')"
    else
        # User-provided version list, make sure we only accept dev versions
        purge_versions="$(echo "${purge_versions}" | sed 's/ /\n/g' \
                            | grep -E '(main|alpha|beta|stable|lts)-[0-9]+\.[0-9]+\.[0-9]+\-.*' \
                            | grep -vE '(-pro)$')"
        keep=0
    fi

    source ci-automation/ci_automation_common.sh

    local sshcmd="$(gen_sshcmd)"

    echo
    echo "######## The following version(s) will be purged ########"
    if [ "$dry_run" = "y" ] ; then
        echo
        echo "(NOTE this is just a dry run since DRY_RUN=y)"
        echo
    fi
    echo "${purge_versions}" | awk '{if ($0 == "") next; printf "%5d %s\n", NR, $0}'
    echo
    echo

    local version
    for version in ${purge_versions}; do
        echo "--------------------------------------------"
        echo
        echo "#### Processing version '${version}' ####"
        echo

        git checkout "${version}" -- sdk_container/.repo/manifests/version.txt
        source sdk_container/.repo/manifests/version.txt

        # Assuming that the SDK build version also has the same OS version
        local os_vernum="${FLATCAR_VERSION}"
        local os_docker_vernum="$(vernum_to_docker_image_version "${FLATCAR_VERSION}")"

        # Remove container image tarballs and SDK tarball (if applicable)
        # Keep in sync with "orphaned directories" clean-up below.
        local rmpat=""
        rmpat="${BUILDCACHE_PATH_PREFIX}/sdk/*/${os_vernum}/"
        rmpat="${rmpat} ${BUILDCACHE_PATH_PREFIX}/containers/${os_docker_vernum}/flatcar-sdk-*"
        rmpat="${rmpat} ${BUILDCACHE_PATH_PREFIX}/containers/${os_docker_vernum}/flatcar-packages-*"
        rmpat="${rmpat} ${BUILDCACHE_PATH_PREFIX}/boards/*/${os_vernum}/"
        rmpat="${rmpat} ${BUILDCACHE_PATH_PREFIX}/containers/${os_docker_vernum}/flatcar-images-*"
        rmpat="${rmpat} ${BUILDCACHE_PATH_PREFIX}/images/*/${os_vernum}/"
        rmpat="${rmpat} ${BUILDCACHE_PATH_PREFIX}/testing/${os_vernum}/"

        echo "## The following files will be removed ##"
        $sshcmd "${BUILDCACHE_USER}@${BUILDCACHE_SERVER}" \
            "ls -la ${rmpat} || true"

        if [ "$dry_run" != "y" ] ; then
            set -x
            $sshcmd "${BUILDCACHE_USER}@${BUILDCACHE_SERVER}" \
                "rm -rf ${rmpat}"
            set +x
        else
            echo "## (DRY_RUN=y so not doing anything) ##"
        fi

        # Remove container image directory if empty
        #
        rmpat="${BUILDCACHE_PATH_PREFIX}/containers/${os_docker_vernum}/"

        echo "## Checking if container directory is empty and can be removed (it's OK if this fails) ##"
        echo "## The following directory will be removed if below output is empty: '${rmpat}' ##"
        $sshcmd "${BUILDCACHE_USER}@${BUILDCACHE_SERVER}" \
            "ls -la ${rmpat} || true"

        if [ "$dry_run" != "y" ] ; then
            set -x
            $sshcmd "${BUILDCACHE_USER}@${BUILDCACHE_SERVER}" \
                "rmdir ${rmpat} || true"
            set +x
        else
            echo "## (DRY_RUN=y so not doing anything) ##"
        fi

        # Remove git tag (local and remote)
        #
        echo "## The following TAG will be deleted: '${version}' ##"
        if [ "$dry_run" != "y" ] ; then
            set -x
            git tag -d "${version}"
            git push --delete origin "${version}"
            set +x
        else
            echo "## (DRY_RUN=y so not doing anything) ##"
        fi
    done

    echo
    echo "########################################"
    echo
    echo    Checking for orphaned directories
    echo

    local dir=""
    for dir in  "sdk/amd64" \
                "containers" \
                "boards/amd64-usr" \
                "boards/arm64-usr" \
                "images/amd64" \
                "images/arm64" \
                "testing" \
                ; do
        local fullpath="${BUILDCACHE_PATH_PREFIX}/${dir}"
        echo
        echo "## Processing '${fullpath}'"
        echo "---------------------------"
        local version=""
        for version in $($sshcmd "${BUILDCACHE_USER}@${BUILDCACHE_SERVER}" "ls -1 ${BUILDCACHE_PATH_PREFIX}/${dir}"); do
            if [ "${dir}" = "containers" ] && echo "${version/+/-}" | grep -qE '.*-github-.*'; then
                echo "Ignoring github CI SDK container in '${fullpath}/${version}'."
                echo "Github CI SDK artifacts are handled by 'garbage_collect_github_ci_sdk.sh'"
                echo " in a later step".
                continue
            fi
            if ! git tag -l | grep -q "${version/+/-}"; then
                local o_fullpath="${fullpath}/${version}"
                echo
                echo "## No tag '${version/+/-}' for orphan directory '${o_fullpath}'; removing."
                echo "## The following files will be removed ##"
                $sshcmd "${BUILDCACHE_USER}@${BUILDCACHE_SERVER}" \
                    "ls -la ${o_fullpath} || true"

                if [ "$dry_run" != "y" ] ; then
                    set -x
                    $sshcmd "${BUILDCACHE_USER}@${BUILDCACHE_SERVER}" \
                        "rm -rf ${o_fullpath} || true"
                    set +x
                else
                    echo "## (DRY_RUN=y so not doing anything) ##"
                fi
                echo
            fi
         done
    done

    echo
    echo "########################################"
    echo
    echo    Running cloud garbage collector
    echo

    local mantle_ref
    mantle_ref=$(cat sdk_container/.repo/manifests/mantle-container)
    docker run --pull always --rm --net host \
      --env AZURE_AUTH_CREDENTIALS --env AZURE_PROFILE \
      --env AWS_ACCESS_KEY_ID --env AWS_SECRET_ACCESS_KEY \
      --env AWS_CREDENTIALS \
      --env DIGITALOCEAN_TOKEN_JSON \
      --env EQUINIXMETAL_KEY --env EQUINIXMETAL_PROJECT \
      --env GCP_JSON_KEY \
      --env VMWARE_ESX_CREDS \
      --env OPENSTACK_CREDS \
      --env BRIGHTBOX_CLIENT_ID --env BRIGHTBOX_CLIENT_SECRET \
      --env AKAMAI_TOKEN \
      -w /work -v "$PWD":/work "${mantle_ref}" /work/ci-automation/garbage_collect_cloud.sh

    echo
    echo "#############################################"
    echo
    echo    Running Github CI SDK garbage collector
    echo

    source ci-automation/garbage_collect_github_ci_sdk.sh
    garbage_collect_github_ci 1 "${min_age_days}"

    echo
    echo "########################################"
    echo
    echo    Running Release Artifacts cache garbage collector
    echo
    source ci-automation/garbage_collect_releases.sh
    garbage_collect_releases
}
# --
