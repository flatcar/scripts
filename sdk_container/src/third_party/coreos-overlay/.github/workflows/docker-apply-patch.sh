#!/bin/bash

set -euo pipefail

branch="docker-${VERSION_NEW}"

pushd ~/flatcar-sdk/src/third_party/coreos-overlay || exit
git checkout -B "${branch}" "github/${BASE_BRANCH}"

VERSION_OLD=$(sed -n "s/^DIST docker-\([0-9]*.[0-9]*.[0-9]*\).*/\1/p" app-emulation/docker/Manifest | sort -ruV | head -n1)
[[ "${VERSION_NEW}" = "${VERSION_OLD}" ]] && echo "already the latest Docker, nothing to do" && exit

# we need to update not only the main ebuild file, but also its DOCKER_GITCOMMIT,
# which needs to point to COMMIT_HASH that matches with $VERSION_NEW from upstream docker-ce.
dockerEbuildOldSymlink=$(ls -1 app-emulation/docker/docker-${VERSION_OLD}*.ebuild | sort -ruV | head -n1)
dockerEbuildNewSymlink="app-emulation/docker/docker-${VERSION_NEW}.ebuild"
dockerEbuildMain="app-emulation/docker/docker-9999.ebuild"
git mv ${dockerEbuildOldSymlink} ${dockerEbuildNewSymlink}
sed -i "s/DOCKER_GITCOMMIT=\"\(.*\)\"/DOCKER_GITCOMMIT=\"${COMMIT_HASH}\"/g" ${dockerEbuildMain}
sed -i "s/v${VERSION_OLD}/v${VERSION_NEW}/g" ${dockerEbuildMain}

# torcx ebuild file has a docker version with only major and minor versions, like 19.03.
versionTorcx=${VERSION_OLD%.*}
torcxEbuildFile=$(ls -1 app-torcx/docker/docker-${versionTorcx}*.ebuild | sort -ruV | head -n1)
sed -i "s/docker-${VERSION_OLD}/docker-${VERSION_NEW}/g" ${torcxEbuildFile}

# update also docker versions used by the current docker-runc ebuild file.
versionRunc=$(sed -n "s/^DIST docker-runc-\([0-9]*.[0-9]*.*\)\.tar.*/\1/p" app-emulation/docker-runc/Manifest | sort -ruV | head -n1)
runcEbuildFile=$(ls -1 app-emulation/docker-runc/docker-runc-${versionRunc}*.ebuild | sort -ruV | head -n1)
sed -i "s/github.com\/docker\/docker-ce\/blob\/v${VERSION_OLD}/github.com\/docker\/docker-ce\/blob\/v${VERSION_NEW}/g" ${runcEbuildFile}

function enter() ( cd ../../..; exec cork enter -- $@ )

# Update manifest and regenerate metadata
enter ebuild "/mnt/host/source/src/third_party/coreos-overlay/app-emulation/docker/docker-${VERSION_NEW}.ebuild" manifest --force

# We can only create the actual commit in the actual source directory, not under the SDK.
# So create a format-patch, and apply to the actual source.
git add app-emulation/docker/docker-${VERSION_NEW}* app-torcx metadata
git commit -a -m "app-emulation/docker: Upgrade Docker ${VERSION_OLD} to ${VERSION_NEW}"

# Generate metadata after the main commit was done.
enter /mnt/host/source/src/scripts/update_metadata --commit coreos

# Create 2 patches, one for the main ebuilds, the other for metadata changes.
git format-patch -2 HEAD
popd || exit

git config user.name 'Flatcar Buildbot'
git config user.email 'buildbot@flatcar-linux.org'
git reset --hard HEAD
git fetch origin
git checkout -B "${BASE_BRANCH}" "origin/${BASE_BRANCH}"
git am ~/flatcar-sdk/src/third_party/coreos-overlay/0*.patch

echo ::set-output name=VERSION_OLD::"${VERSION_OLD}"
