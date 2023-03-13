#!/bin/bash

set -euo pipefail

stage1_repo="${1}"
new_repo="${2}"

good_version="3.6.8-r10"
stage1_version=''

for f in "${stage1_repo}/sys-apps/baselayout/baselayout-"*'.ebuild'; do
    f="${f##*/}"
    if [[ "${f}" = *9999* ]]; then continue; fi
    f="${f%.ebuild}"
    f="${f#baselayout-}"
    stage1_version="${f}"
done

if [[ -z "${stage1_version}" ]]; then exit 1; fi

older_version=$(printf '%s\n' "${stage1_version}" "${good_version}" | sort -V | head -n 1)

if [[ "${older_version}" = "${good_version}" ]]; then
    # Stage1 version is equal or newer than the good version, nothing
    # to do.
    exit 0
fi

rm -rf "${stage1_repo}/sys-apps/baselayout"
cp -a "${new_repo}/sys-apps/baselayout" "${stage1_repo}/sys-apps/baselayout"
