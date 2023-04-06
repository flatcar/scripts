#!/bin/bash

set -euo pipefail

source "${GHA_SCRIPTS_DIR}/.github/workflows/common.sh"

prepare_git_repo

pushd "${SDK_OUTER_OVERLAY}"

VERSION_OLD=$(sed -n "s/^DIST docker-\([0-9]*.[0-9]*.[0-9]*\).*/\1/p" app-emulation/docker/Manifest | sort -ruV | head -n1)
if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
  echo "already the latest Docker, nothing to do"
  exit 0
fi

# we need to update not only the main ebuild file, but also its DOCKER_GITCOMMIT,
# which needs to point to COMMIT_HASH that matches with $VERSION_NEW from upstream docker-ce.
dockerEbuildOld=$(get_ebuild_filename app-emulation/docker "${VERSION_OLD}")
dockerEbuildNew="app-emulation/docker/docker-${VERSION_NEW}.ebuild"
git mv "${dockerEbuildOld}" "${dockerEbuildNew}"
sed -i "s/GIT_COMMIT=\(.*\)/GIT_COMMIT=${COMMIT_HASH_MOBY}/g" "${dockerEbuildNew}"
sed -i "s/v${VERSION_OLD}/v${VERSION_NEW}/g" "${dockerEbuildNew}"

cliEbuildOld=$(get_ebuild_filename app-emulation/docker-cli "${VERSION_OLD}")
cliEbuildNew="app-emulation/docker-cli/docker-cli-${VERSION_NEW}.ebuild"
git mv "${cliEbuildOld}" "${cliEbuildNew}"
sed -i "s/GIT_COMMIT=\(.*\)/GIT_COMMIT=${COMMIT_HASH_CLI}/g" "${cliEbuildNew}"
sed -i "s/v${VERSION_OLD}/v${VERSION_NEW}/g" "${cliEbuildNew}"

# torcx ebuild file has a docker version with only major and minor versions, like 19.03.
versionTorcx=${VERSION_OLD%.*}
torcxEbuildFile=$(get_ebuild_filename app-torcx/docker "${versionTorcx}")
sed -i "s/docker-${VERSION_OLD}/docker-${VERSION_NEW}/g" "${torcxEbuildFile}"
sed -i "s/docker-cli-${VERSION_OLD}/docker-cli-${VERSION_NEW}/g" "${torcxEbuildFile}"

# update also docker versions used by the current docker-runc ebuild file.
versionRunc=$(sed -n "s/^DIST docker-runc-\([0-9]*.[0-9]*.*\)\.tar.*/\1/p" app-emulation/docker-runc/Manifest | sort -ruV | head -n1)
runcEbuildFile=$(get_ebuild_filename app-emulation/docker-runc "${versionRunc}")
sed -i "s/github.com\/docker\/docker-ce\/blob\/v${VERSION_OLD}/github.com\/docker\/docker-ce\/blob\/v${VERSION_NEW}/g" ${runcEbuildFile}

popd

# URL for Docker release notes has a specific format of
#   https://docs.docker.com/engine/release-notes/MAJOR.MINOR/#COMBINEDFULLVERSION
# To get the subfolder part MAJOR.MINOR, drop the patchlevel of the semver.
#   e.g. 20.10.23 -> 20.10
# To get the combined full version, drop all dots from the full version.
#   e.g. 20.10.23 -> 201023
# So the result becomes like:
#   https://docs.docker.com/engine/release-notes/20.10/#201023
URLSUBFOLDER=${VERSION_NEW%.*}
URLVERSION="${VERSION_NEW//./}"
URL="https://docs.docker.com/engine/release-notes/${URLSUBFOLDER}/#${URLVERSION}"

generate_update_changelog 'Docker' "${VERSION_NEW}" "${URL}" 'docker'

regenerate_manifest app-emulation/docker-cli "${VERSION_NEW}"
commit_changes app-emulation/docker "${VERSION_OLD}" "${VERSION_NEW}" \
               app-emulation/docker-cli \
               app-torcx/docker \
               app-emulation/docker-runc

cleanup_repo

echo "VERSION_OLD=${VERSION_OLD}" >>"${GITHUB_OUTPUT}"
echo 'UPDATE_NEEDED=1' >>"${GITHUB_OUTPUT}"
