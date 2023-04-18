#!/bin/bash

set -euo pipefail

source "${GHA_SCRIPTS_DIR}/.github/workflows/common.sh"

prepare_git_repo

pushd "${SDK_OUTER_OVERLAY}"

# Parse the Manifest file for already present source files and keep the latest version in the current series
VERSION_OLD=$(sed -n "s/^DIST nss-\([0-9]*\.[0-9]*\).*$/\1/p" app-misc/ca-certificates/Manifest | sort -ruV | head -n1)
if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
  echo "already the latest ca-certificates, nothing to do"
  exit 0
fi

EBUILD_FILENAME=$(get_ebuild_filename app-misc/ca-certificates "${VERSION_OLD}")
git mv "${EBUILD_FILENAME}" "app-misc/ca-certificates/ca-certificates-${VERSION_NEW}.ebuild"

popd

URLVERSION=$(echo "${VERSION_NEW}" | tr '.' '_')
URL="https://firefox-source-docs.mozilla.org/security/nss/releases/nss_${URLVERSION}.html"

generate_update_changelog 'ca-certificates' "${VERSION_NEW}" "${URL}" 'ca-certificates'

commit_changes app-misc/ca-certificates "${VERSION_OLD}" "${VERSION_NEW}"

cleanup_repo

echo "VERSION_OLD=${VERSION_OLD}" >>"${GITHUB_OUTPUT}"
echo 'UPDATE_NEEDED=1' >>"${GITHUB_OUTPUT}"
