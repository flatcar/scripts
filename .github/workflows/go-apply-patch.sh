#!/bin/bash

set -euo pipefail

source "${GHA_SCRIPTS_DIR}/.github/workflows/common.sh"

prepare_git_repo

# create a mapping between short version and new version, e.g. 1.16 -> 1.16.3
declare -A VERSIONS
for version_new in ${VERSIONS_NEW}; do
  version_new_trimmed="${version_new%.*}"
  if [[ "${version_new_trimmed%.*}" = "${version_new_trimmed}" ]]; then
    version_new_trimmed="${version_new}"
  fi
  VERSIONS["${version_new_trimmed}"]="${version_new}"
done

branch_name="go-$(join_by '-and-' ${VERSIONS_NEW})-main"

if ! check_remote_branch "${branch_name}"; then
  echo "remote branch already exists, nothing to do"
  exit 0
fi

# Parse the Manifest file for already present source files and keep the latest version in the current series
# DIST go1.17.src.tar.gz ... => 1.17
# DIST go1.17.1.src.tar.gz ... => 1.17.1
declare -a UPDATED_VERSIONS_OLD UPDATED_VERSIONS_NEW
any_different=0
for version_short in "${!VERSIONS[@]}"; do
  pushd "${SDK_OUTER_OVERLAY}"
  VERSION_NEW="${VERSIONS["${version_short}"]}"
  VERSION_OLD=$(sed -n "s/^DIST go\(${version_short}\(\.*[0-9]*\)\?\)\.src.*/\1/p" dev-lang/go/Manifest | sort -ruV | head -n1)
  if [[ -z "${VERSION_OLD}" ]]; then
    echo "${version_short} is not packaged, skipping"
    popd
    continue
  fi
  if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
    echo "${version_short} is already at the latest (${VERSION_NEW}), skipping"
    popd
    continue
  fi
  UPDATED_VERSIONS_OLD+=("${VERSION_OLD}")
  UPDATED_VERSIONS_NEW+=("${VERSION_NEW}")

  any_different=1
  EBUILD_FILENAME=$(get_ebuild_filename dev-lang/go "${VERSION_OLD}")
  git mv "${EBUILD_FILENAME}" "dev-lang/go/go-${VERSION_NEW}.ebuild"

  popd

  URL="https://go.dev/doc/devel/release#go${VERSION_NEW}"

  generate_update_changelog 'Go' "${VERSION_NEW}" "${URL}" 'go'

  commit_changes dev-lang/go "${VERSION_OLD}" "${VERSION_NEW}"
done

cleanup_repo

if [[ $any_different -eq 0 ]]; then
    echo "go packages were already at the latest versions, nothing to do"
    exit 0
fi

vo_gh="$(join_by ' and ' "${UPDATED_VERSIONS_OLD[@]}")"
vn_gh="$(join_by ' and ' "${UPDATED_VERSIONS_NEW[@]}")"

echo "VERSIONS_OLD=${vo_gh}" >>"${GITHUB_OUTPUT}"
echo "VERSIONS_NEW=${vn_gh}" >>"${GITHUB_OUTPUT}"
echo "BRANCH_NAME=${branch_name}" >>"${GITHUB_OUTPUT}"
echo 'UPDATE_NEEDED=1' >>"${GITHUB_OUTPUT}"
