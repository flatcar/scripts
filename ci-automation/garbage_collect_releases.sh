#!/bin/bash
#
# Copyright (c) 2024 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# garbage_collect_releases() should be called after sourcing.
#
#  OPTIONAL INPUT
#  - Number releases to keep per channel. Defaults to 10.
#  - Number of LTS channels to keep. Defaults to 2 (i.e. the current and the previous (deprecated) LTS).
#  - DRY_RUN (Env variable). Set to "y" to just list what would be done but not
#            actually purge anything.

# Flatcar build cache releases artifacts garbage collector.
#  This script removes release artifacts of past releases from the build cache.
#  Note that release artifacts are copied to official mirrors upon release, so there's
#   no need to keep a copy on the build cache server.

function garbage_collect_releases() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _garbage_collect_releases_impl "${@}"
    )
}
# --

function _garbage_collect_releases_impl() {
    local keep_per_chan="${1:-10}"
    local keep_lts_releases="${2:-2}"
    local dry_run="${DRY_RUN:-}"

    echo
    echo "Number of versions to keep per channel: '${keep_per_chan}'"
    echo "Number of LTS major releases to keep: '${keep_lts_releases}'"
    echo

    source ci-automation/ci_automation_common.sh
    local sshcmd="$(gen_sshcmd)"

    local keep_versions
    mapfile -t keep_versions < <(unset POSIXLY_CORRECT; \
        curl -s "${RELEASES_JSON_FEED}" \
        | jq -r 'keys_unsorted | .[] | match("[0-9]+\\.[0-9]+\\.[0-9]+") | .string' \
        | sort -Vr \
        | awk -v keep="${keep_per_chan}" -v lts="${keep_lts_releases}" '
            {
                version = $1
                chan_num = gensub("[0-9]+\\.([0-9]+)\\.[0-9]+","\\1","g", version) + 0
                major = gensub("([0-9]+)\\.[0-9]+\\.[0-9]+","\\1","g", version) + 0

                if (chan_num <= 2) {
                    if (chan_count[chan_num] < keep)
                        print version
                    chan_count[chan_num] = chan_count[chan_num] + 1
                } else {
                    if (    (chan_count["lts"][major] < keep) \
                         && (length(chan_count["lts"]) <= lts) )
                        print version
                    chan_count["lts"][major] = chan_count["lts"][major] + 1
                }
            } ')

    echo
    echo "######## The following version(s) will be kept ########"
    if [ "$dry_run" = "y" ] ; then
        echo
        echo "(NOTE this is just a dry run since DRY_RUN=y)"
        echo
    fi
    printf "%s\n" "${keep_versions[@]}"

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
        for version in $($sshcmd "${BUILDCACHE_USER}@${BUILDCACHE_SERVER}" \
                                 "ls -1 ${BUILDCACHE_PATH_PREFIX}/${dir} | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$'"); do
            local o_fullpath="${fullpath}/${version}"

            # skip if version is marked for keeping OR if it's a new release about to be published
            if printf "%s\n" "${keep_versions[@]}" \
               | { unset POSIXLY_CORRECT ; awk -v version="${version}" -v path="${dir}" '
                BEGIN {
                    vmajor = gensub("([0-9]+)\\.[0-9]+\\.[0-9]+","\\1","g", version) + 0
                    vminor = gensub("[0-9]+\\.([0-9]+)\\.[0-9]+","\\1","g", version) + 0
                    vpatch = gensub("[0-9]+\\.[0-9]+\\.([0-9]+)","\\1","g", version) + 0
                    ret = 1
                }

                {
                    if ($0 == version) {
                        print ""
                        print "## Skipping " version " because it is in the keep list."
                        ret = 0
                        exit
                    }

                    major = gensub("([0-9]+)\\.[0-9]+\\.[0-9]+","\\1","g") + 0
                    minor = gensub("[0-9]+\\.([0-9]+)\\.[0-9]+","\\1","g") + 0
                    patch = gensub("[0-9]+\\.[0-9]+\\.([0-9]+)","\\1","g") + 0

                    if (   ((path == "sdk/amd64") || (path == "containers")) \
                        && (vmajor == major) && (vminor == 0) && (vpatch == 0) ) {
                        print ""
                        print "## Skipping " version " in " path " because it contains the SDK for release " $0 " in keep list."
                        ret = 0
                        exit
                    }

                    if (major_alpha == "")
                        major_alpha = major

                    if (vmajor > major_alpha) {
                        print ""
                        print "## Skipping " version " because major version is higher than the latest Alpha (" major_alpha ") in keep list."
                        print "(I.e. this is an unpublished new Alpha release)"
                        ret = 0
                        exit
                    }

                    if ((vmajor == major) && (vminor > minor)) {
                        print ""
                        print "## Skipping " version " because major version is in keep list and minor version is higher than the latest release."
                        print "(I.e. this is an unpublished channel progression " $0 " -> " version ")"
                        ret = 0
                        exit
                    }

                    if ((vmajor == major) && (vminor == minor) && (vpatch > patch)) {
                        print ""
                        print "## Skipping " version " because major and minor versions are in keep list and patch version is higher than the latest release."
                        print "(I.e. this is an unpublished new patch release " $0 " -> " version ")"
                        ret = 0
                        exit
                    }
                }

                END {
                    exit ret
                }' ; } then
                continue
            fi

            echo
            echo "## Removing version '${version}' in '${o_fullpath}'"
            echo

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
        done
    done
}
# --
