#!/bin/bash

set -euo pipefail

git fetch origin
git checkout -B "${BASE_BRANCH}" "origin/${BASE_BRANCH}"

pushd "virtual/rust" >/dev/null || exit
VERSION_OLD=$(ls -1 rust-*.ebuild | sed -n "s/rust-\(1.[0-9]*.[0-9]*\).ebuild/\1/p" | sort -ruV | head -n1)
git mv rust-${VERSION_OLD}.ebuild "rust-${VERSION_NEW}.ebuild"
# For a complete update we would need to download the upstream ebuild and apply our crossdev patch.
# Automating this is not done yet and maybe would not work well either and had the same result as just renaming
# which we did here and has the same effect for minor updates that do not touch the ebuild logic.
popd >/dev/null || exit

echo ::set-output name=VERSION_OLD::"${VERSION_OLD}"
