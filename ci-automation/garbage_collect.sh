#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# garbage_collect() should be called after sourcing.
#
#  OPTIONAL INPUT
#  - Number of (recent) versions to keep. Defaults to 50.
#  - PURGE_VERSIONS (Env variable). Space-separated list of versions to purge
#            instead of all but the 50 most recent ones.
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
    local keep="${1:-50}"
    local dry_run="${DRY_RUN:-}"
    local purge_versions="${PURGE_VERSIONS:-}"

    local versions_detected="$(git tag -l --sort=-committerdate \
                | grep -E '(main|alpha|beta|stable|lts)-[0-9]+\.[0-9]+\.[0-9]+\-.*' \
                | grep -vE '(-pro)$')"

    echo "######## Full list of version(s) found ########"
    echo "${versions_detected}" | awk '{printf "%5d %s\n", NR, $0}'

    if [ -z "${purge_versions}" ] ; then
        keep="$((keep + 1))" # for tail -n+...
        purge_versions="$(echo "${versions_detected}" \
                            | tail -n+"${keep}")"
    else
        # make sure we only accept dev versions
        purge_versions="$(echo "${purge_versions}" | sed 's/ /\n/g' \
                            | grep -E '(main|alpha|beta|stable|lts)-[0-9]+\.[0-9]+\.[0-9]+\-.*' \
                            | grep -vE '(-pro)$')"
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
    echo "${purge_versions}" | awk -v keep="${keep}" '{if ($0 == "") next; printf "%5d %s\n", NR + keep - 1, $0}'
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
        #
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
    echo    Running cloud garbace collector
    echo

    local mantle_ref
    mantle_ref=$(cat sdk_container/.repo/manifests/mantle-container)
    docker run --pull always --rm --net host \
      --env AZURE_AUTH_CREDENTIALS --env AZURE_PROFILE \
      --env AWS_ACCESS_KEY_ID --env AWS_SECRET_ACCESS_KEY \
      --env DIGITALOCEAN_TOKEN_JSON \
      --env EQUINIXMETAL_KEY --env EQUINIXMETAL_PROJECT \
      --env GCP_JSON_KEY \
      --env VMWARE_ESX_CREDS \
      --env OPENSTACK_CREDS \
      -w /work -v "$PWD":/work "${mantle_ref}" /work/ci-automation/garbage_collect_cloud.sh

    echo
    echo "#############################################"
    echo
    echo    Running Github CI SDK garbace collector
    echo

    source ci-automation/garbage_collect_github_ci_sdk.sh
    garbage_collect_github_ci
}
# --
