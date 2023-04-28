#!/bin/bash

set -euo pipefail

source "${GHA_SCRIPTS_DIR}/.github/workflows/common.sh"

prepare_git_repo

if ! check_remote_branch "rust-${VERSION_NEW}-${TARGET_BRANCH}"; then
    echo "remote branch already exists, nothing to do"
    exit 0
fi

pushd "${SDK_OUTER_OVERLAY}"

VERSION_OLD=$(sed -n "s/^DIST rustc-\(1\.[0-9]*\.[0-9]*\).*/\1/p" dev-lang/rust/Manifest | sort -ruV | head -n1)
if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
    echo "already the latest Rust, nothing to do"
    exit 0
fi

# Replace (dev-lang/virtual)/rust versions in profiles/, e.g. package.accept_keywords.
# Try to match all kinds of version specifiers, e.g. >=, <=, =, ~.
find profiles -name 'package.*' | xargs sed -i "s/\([><]*=\|~\)*dev-lang\/rust-\S\+/\1dev-lang\/rust-${VERSION_NEW}/"
find profiles -name 'package.*' | xargs sed -i "s/\([><]*=\|~\)*virtual\/rust-\S\+/\1virtual\/rust-${VERSION_NEW}/"

EBUILD_FILENAME=$(get_ebuild_filename dev-lang/rust "${VERSION_OLD}")
git mv "${EBUILD_FILENAME}" "dev-lang/rust/rust-${VERSION_NEW}.ebuild"
EBUILD_FILENAME=$(get_ebuild_filename virtual/rust "${VERSION_OLD}")
git mv "${EBUILD_FILENAME}" "virtual/rust/rust-${VERSION_NEW}.ebuild"

popd

URL="https://github.com/rust-lang/rust/releases/tag/${VERSION_NEW}"

generate_update_changelog 'Rust' "${VERSION_NEW}" "${URL}" 'rust'

commit_changes dev-lang/rust "${VERSION_OLD}" "${VERSION_NEW}" \
               profiles \
               virtual/rust

cleanup_repo

echo "VERSION_OLD=${VERSION_OLD}" >>"${GITHUB_OUTPUT}"
echo 'UPDATE_NEEDED=1' >>"${GITHUB_OUTPUT}"
