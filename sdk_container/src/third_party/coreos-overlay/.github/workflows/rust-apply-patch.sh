#!/bin/bash

set -euo pipefail

UPDATE_NEEDED=1

. .github/workflows/common.sh

if ! checkout_branches "rust-${VERSION_NEW}-${TARGET}"; then
  UPDATE_NEEDED=0
  exit 0
fi

pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit

VERSION_OLD=$(sed -n "s/^DIST rustc-\(1.[0-9]*.[0-9]*\).*/\1/p" dev-lang/rust/Manifest | sort -ruV | head -n1)
if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
  echo "already the latest Rust, nothing to do"
  UPDATE_NEEDED=0
  exit 0
fi

# replace rust version in profiles/, e.g. package.accept_keywords.
find profiles -name 'package.*' | xargs sed -i "s/=dev-lang\/rust-${VERSION_OLD}/=dev-lang\/rust-${VERSION_NEW}/"

pushd "dev-lang/rust" >/dev/null || exit
git mv $(ls -1 rust-${VERSION_OLD}*.ebuild | sort -ruV | head -n1) "rust-${VERSION_NEW}.ebuild"
popd >/dev/null || exit

popd >/dev/null || exit

generate_patches dev-lang rust dev-lang/rust

apply_patches

echo ::set-output name=VERSION_OLD::"${VERSION_OLD}"
echo ::set-output name=UPDATE_NEEDED::"${UPDATE_NEEDED}"
