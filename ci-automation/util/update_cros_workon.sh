#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Helper script to update an ebuild's CROS_WORKON_COMMIT to the tip of a branch
#  (HEAD by default).
#
# PREREQUISITES:
#
#   1. The ebuild to be updated uses CROS_WORKON_COMMIT.
#   2. the directory the ebuild is in follows the pattern of
#      - exactly one "versioned" ebuild which is a soft-link to the actual ebuild
#      - the actual ebuild conforms to <name>-9999.ebuild
#
# INPUT
#
#   1. Path to the ebuild directory.
#
# OPTIONAL INPUT
#
#   2. Branch to update the ebuild to. The latest commit of the branch will be used.
#       Defaults to HEAD (i.e. the repo's default branch).
#   3. "false" by default.
#      "commit" - create a git commit both in the submodule as well as in scripts after updating.
#      "push" - implies "commit". Create commits and push the submodule branch (but not "scripts").
#

function update_cros_workon() {
    set -euo pipefail

    local ebuild_dir="$1"
    local branch="${2:-HEAD}"
    local commit="${3:-false}"

    # Use a subshell and operate directly in $ebuild_dir
    (
        cd "${ebuild_dir}"
        softlink="$(basename $(find . -type l))"

        name="$(echo "${softlink}" | sed 's/^\(.*\)-[0-9.]\+[-.]*.*\.ebuild/\1/')"
        version="$(echo "${softlink}" | sed 's/^.*-\([0-9.]\+\)[-.]*.*\.ebuild/\1/')"
        release="$(echo "${softlink}" | sed -n 's/.*-[0-9.]\+[-.]r\([0-9]\+\)\.ebuild/\1/p')"
        new_release="$((release + 1))"

        ebuild="${name}-9999.ebuild"
        new_softlink="${name}-${version}-r${new_release}.ebuild"
        ln -s "${ebuild}" "${new_softlink}"

        local repo="$(eval "$(grep -E '^\s*(CROS_WORKON_REPO|CROS_WORKON_PROJECT)=' "${ebuild}")"
                      echo $CROS_WORKON_REPO/$CROS_WORKON_PROJECT)"
        commit_id="$(git ls-remote "${repo}" "${branch}" | awk "/[[:space:]]${branch}/ {print \$1}")"

        sed -i "s/CROS_WORKON_COMMIT=.*/CROS_WORKON_COMMIT=\"${commit_id}\" # tip of branch ${branch} $(date)/" \
                "${ebuild}"

        rm "${softlink}"

        echo "Updated '${ebuild}' to commit '${commit_id}'"
        echo " ('${softlink}' ==> '${new_softlink}'"

        if [[ "${commit}" =~ (commit|push) ]] ; then
            git add .
            local category="$(dirname "${PWD}")"
            category="${category##*/}" # strip everything from the beginning to the last slash
            git commit -m "${category}/${name}: Update to latest ${branch}"

            if [ "${commit}" = "push" ] ; then
                git push
            fi
        fi
    )

    if [[ "${commit}" =~ (commit|push) ]] ; then
        local submodule_path="$(echo "${ebuild_dir}" \
                                | sed -n 's/\(coreos-overlay\|portage-stable\).*/\1/p')"
        local submodule="$(basename "${submodule_path}")"
        git commit -m "${submodule}: Update ${name} to latest ${branch}" "${submodule_path}"
    fi
}
# --

if [ "$(basename "${BASH_SOURCE[0]}")" = "update_cros_workon.sh" ] ; then
    update_cros_workon $@
fi
