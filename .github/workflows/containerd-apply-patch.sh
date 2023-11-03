#!/bin/bash

set -euo pipefail

source "${GHA_SCRIPTS_DIR}/.github/workflows/common.sh"

prepare_git_repo

if ! check_remote_branch "containerd-${VERSION_NEW}-${TARGET_BRANCH}"; then
    echo "remote branch already exists, nothing to do"
    exit 0
fi

pushd "${SDK_OUTER_OVERLAY}"

VERSION_OLD=$(sed -n "s/^DIST containerd-\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p" app-containers/containerd/Manifest | sort -ruV | head -n1)
if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
    echo "already the latest Containerd, nothing to do"
    exit 0
fi

# we need to update not only the main ebuild file, but also its CONTAINERD_COMMIT,
# which needs to point to COMMIT_HASH that matches with $VERSION_NEW from upstream containerd.
containerdEbuildOld=$(get_ebuild_filename app-containers/containerd "${VERSION_OLD}")
containerdEbuildNew="app-containers/containerd/containerd-${VERSION_NEW}.ebuild"
git mv "${containerdEbuildOld}" "${containerdEbuildNew}"
sed -i "s/GIT_REVISION=.*/GIT_REVISION=${COMMIT_HASH}/g" "${containerdEbuildNew}"

# The ebuild is masked by default to maintain compatibility with Gentoo upstream
#  so we add an unmask for Flatcar only.
keywords_file="profiles/coreos/base/package.accept_keywords"
ts=$(date +'%Y-%m-%d %H:%M:%S')
comment="DO NOT EDIT THIS LINE. Added by containerd-apply-patch.sh on ${ts}"
sed -i "s;^\(=app-containers/containerd\)-${VERSION_OLD} .*;\1-${VERSION_NEW} ~amd64 ~arm64 # ${comment};" "${keywords_file}"

popd

URL="https://github.com/containerd/containerd/releases/tag/v${VERSION_NEW}"

generate_update_changelog 'containerd' "${VERSION_NEW}" "${URL}" 'containerd'

# Commit package changes and updated keyword file
commit_changes app-containers/containerd "${VERSION_OLD}" "${VERSION_NEW}" "${keywords_file}"

cleanup_repo

echo "VERSION_OLD=${VERSION_OLD}" >>"${GITHUB_OUTPUT}"
echo 'UPDATE_NEEDED=1' >>"${GITHUB_OUTPUT}"
