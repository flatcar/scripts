#!/bin/bash

set -euo pipefail

UPDATE_NEEDED=1

. .github/workflows/common.sh

if ! checkout_branches "docker-${VERSION_NEW}-${TARGET}"; then
  UPDATE_NEEDED=0
  exit 0
fi

pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit

VERSION_OLD=$(sed -n "s/^DIST docker-\([0-9]*.[0-9]*.[0-9]*\).*/\1/p" app-emulation/docker/Manifest | sort -ruV | head -n1)
if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
  echo "already the latest Docker, nothing to do"
  UPDATE_NEEDED=0
  exit 0
fi

# we need to update not only the main ebuild file, but also its DOCKER_GITCOMMIT,
# which needs to point to COMMIT_HASH that matches with $VERSION_NEW from upstream docker-ce.
dockerEbuildOldSymlink=$(ls -1 app-emulation/docker/docker-${VERSION_OLD}.ebuild)
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

popd >/dev/null || exit

generate_patches app-emulation docker Docker

apply_patches

echo ::set-output name=VERSION_OLD::"${VERSION_OLD}"
echo ::set-output name=UPDATE_NEEDED::"${UPDATE_NEEDED}"
