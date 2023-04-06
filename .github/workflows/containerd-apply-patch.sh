#!/bin/bash

set -euo pipefail

source "${GHA_SCRIPTS_DIR}/.github/workflows/common.sh"

prepare_git_repo

pushd "${SDK_OUTER_OVERLAY}"

VERSION_OLD=$(sed -n "s/^DIST containerd-\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p" app-emulation/containerd/Manifest | sort -ruV | head -n1)
if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
  echo "already the latest Containerd, nothing to do"
  exit 0
fi

# we need to update not only the main ebuild file, but also its CONTAINERD_COMMIT,
# which needs to point to COMMIT_HASH that matches with $VERSION_NEW from upstream containerd.
containerdEbuildOldSymlink=$(get_ebuild_filename app-emulation/containerd "${VERSION_OLD}")
containerdEbuildNewSymlink="app-emulation/containerd/containerd-${VERSION_NEW}.ebuild"
containerdEbuildMain="app-emulation/containerd/containerd-9999.ebuild"
git mv "${containerdEbuildOldSymlink}" "${containerdEbuildNewSymlink}"
sed -i "s/CONTAINERD_COMMIT=\"\(.*\)\"/CONTAINERD_COMMIT=\"${COMMIT_HASH}\"/g" "${containerdEbuildMain}"
sed -i "s/v${VERSION_OLD}/v${VERSION_NEW}/g" "${containerdEbuildMain}"


DOCKER_VERSION=$(sed -n "s/^DIST docker-\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p" app-emulation/docker/Manifest | sort -ruV | head -n1)
# torcx ebuild file has a docker version with only major and minor versions, like 19.03.
versionTorcx=${DOCKER_VERSION%.*}
torcxEbuildFile=$(get_ebuild_filename app-torcx/docker "${versionTorcx}")
sed -i "s/containerd-${VERSION_OLD}/containerd-${VERSION_NEW}/g" "${torcxEbuildFile}"

popd

URL="https://github.com/containerd/containerd/releases/tag/v${VERSION_NEW}"

generate_update_changelog 'containerd' "${VERSION_NEW}" "${URL}" 'containerd'

commit_changes app-emulation/containerd "${VERSION_OLD}" "${VERSION_NEW}" \
               app-torcx/docker

cleanup_repo

echo "VERSION_OLD=${VERSION_OLD}" >>"${GITHUB_OUTPUT}"
echo 'UPDATE_NEEDED=1' >>"${GITHUB_OUTPUT}"
