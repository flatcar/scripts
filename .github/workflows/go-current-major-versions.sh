#!/bin/bash

set -euo pipefail

source "${GHA_SCRIPTS_DIR}/.github/workflows/common.sh"

pushd "${SDK_OUTER_OVERLAY}"

versions=()
for ebuild in dev-lang/go/go-*.ebuild; do
    version="${ebuild##*/go-}" # 1.20.1-r1.ebuild or 1.19.ebuild
    version="${version%.ebuild}" # 1.20.1-r1 or 1.19
    version="${version%%-*}" # 1.20.1 or 1.19
    short_version="${version%.*}" # 1.20 or 1
    if [[ "${short_version%.*}" = "${short_version}" ]]; then
        # fix short version
        short_version="${version}"
    fi

    versions+=($(git ls-remote --tags https://github.com/golang/go | \
                     cut -f2 | \
                     sed --quiet "/refs\/tags\/go${short_version}\(\.[0-9]*\)\?$/s/^refs\/tags\/go//p" | \
                     grep --extended-regexp --invert-match --regexp='(beta|rc)' | \
                     sort --reverse --unique --version-sort | \
                     head --lines=1))
done

popd

echo "VERSIONS_NEW=${versions[*]}" >>"${GITHUB_OUTPUT}"
