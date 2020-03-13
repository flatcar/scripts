#!/bin/bash

set -euo pipefail

git fetch origin
git checkout -B "${BASE_BRANCH}" "origin/${BASE_BRANCH}"

pushd "virtual/rust" >/dev/null || exit
VERSION_OLD=$(ls -1 rust-*.ebuild | sed -n "s/rust-\(1.[0-9]*.[0-9]*\).ebuild/\1/p" | sort -ruV | head -n1)
git mv rust-${VERSION_OLD}.ebuild "rust-${VERSION_NEW}.ebuild"
popd >/dev/null || exit

echo ::set-output name=VERSION_OLD::"${VERSION_OLD}"
