#!/bin/bash

set -euo pipefail

UPDATE_NEEDED=1

. .github/workflows/common.sh

prepare_git_repo

if ! checkout_branches "rust-${VERSION_NEW}-${TARGET}"; then
  UPDATE_NEEDED=0
  exit 0
fi

pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit

VERSION_OLD=$(sed -n "s/^DIST rustc-\(1\.[0-9]*\.[0-9]*\).*/\1/p" dev-lang/rust/Manifest | sort -ruV | head -n1)
if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
  echo "already the latest Rust, nothing to do"
  UPDATE_NEEDED=0
  exit 0
fi

# Replace (dev-lang/virtual)/rust versions in profiles/, e.g. package.accept_keywords.
# Try to match all kinds of version specifiers, e.g. >=, <=, =, ~.
find profiles -name 'package.*' | xargs sed -i "s/\([><]*=\|~\)*dev-lang\/rust-\S\+/\1dev-lang\/rust-${VERSION_NEW}/"
find profiles -name 'package.*' | xargs sed -i "s/\([><]*=\|~\)*virtual\/rust-\S\+/\1virtual\/rust-${VERSION_NEW}/"

EBUILD_FILENAME=$(get_ebuild_filename "dev-lang" "rust" "${VERSION_OLD}")

# Every ebuild for dev-lang/rust does a specific check if PV is the version.
# e.g. if [[ "${PV}" == 1.66.1 ]]; then,
# So it is needed to replace the hard-coded version with the new version.
sed -i "s/PV\(.*\)${VERSION_OLD}/PV\1${VERSION_NEW}/g" ${EBUILD_FILENAME}

git mv "${EBUILD_FILENAME}" "dev-lang/rust/rust-${VERSION_NEW}.ebuild"
EBUILD_FILENAME=$(get_ebuild_filename "virtual" "rust" "${VERSION_OLD}")
git mv "${EBUILD_FILENAME}" "virtual/rust/rust-${VERSION_NEW}.ebuild"

popd >/dev/null || exit

URL="https://github.com/rust-lang/rust/releases/tag/${VERSION_NEW}"

generate_update_changelog 'Rust' "${VERSION_NEW}" "${URL}" 'rust'

generate_patches dev-lang rust dev-lang/rust profiles

apply_patches

echo "VERSION_OLD=${VERSION_OLD}" >>"${GITHUB_OUTPUT}"
echo "UPDATE_NEEDED=${UPDATE_NEEDED}" >>"${GITHUB_OUTPUT}"
