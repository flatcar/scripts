#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# garbage_collect_github_ci() should be called after sourcing.
#
#  OPTIONAL INPUT
#  - Number of (recent) Github SDK builds to keep. Defaults to 20.
#  - DRY_RUN (Env variable). Set to "y" to just list what would be done but not
#            actually purge anything.

# Flatcar Github CI SDK rebuild automation garbage collector.
#  This script removes development (non-official) SDK image builds generated via Github CI.
#
#  Garbage collection is based on development (non-official) SDK versions listed on
#     https://bincache.flatcar-linux.net/containers/
#  and following the pattern [VERSION_NUMBER]*-github-*. The newest 20 builds will be retained,
#   all older builds will be purged (20 is the default, see OPTIONAL INPUT above).

function garbage_collect_github_ci() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _garbage_collect_github_ci_impl "${@}"
    )
}
# --

function _garbage_collect_github_ci_impl() {
    local keep="${1:-50}"
    local dry_run="${DRY_RUN:-}"

    # Example version string
    #   <a href="./3598.0.0-nightly-20230508-2100-github-2023_05_09__08_06_54/">
    #   <a href="./3598.0.0-nightly-20230508-2100-github-pr-12345-2023_05_09__08_06_54/">
    local versions_detected="$(curl -s https://bincache.flatcar-linux.net/containers/ \
                | grep -E '\<a href="\./[0-9]+\.[0-9]+.[0-9]+.+-github-.*/">' \
                | sed 's:.*\"./\([^/]\+\)/".*:\1:' )"

    # Sort versions by date. Since version numbers can differ and this would impact sort, we
    # 1. insert a "/" between "...-github-[pr-XXX]-" and "[date]..."
    # 2. sort with delimiter "/" and sorting key 2 (i.e. the date part)
    # 3. remove the "/"
   local versions_sorted="$(echo "${versions_detected}" \
                        | sed 's/\(-github\(-pr-[0-9]*\)*-\)/\1\//' \
                        | sort -k 2 -t / \
                        | sed 's:/::')"

    echo "######## Full list of version(s) found ########"
    echo "${versions_sorted}" | awk '{printf "%5d %s\n", NR, $0}'

    local keep="$((keep + 1))" # for tail -n+...
    local purge_versions="$(echo "${versions_sorted}" \
                            | tail -n+"${keep}")"

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

    local version=""
    for version in ${purge_versions}; do
        echo "--------------------------------------------"
        echo
        echo "#### Processing version '${version}' ####"
        echo

        local rmpat="${BUILDCACHE_PATH_PREFIX}/containers/${version}/"

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
    done
}
# --
