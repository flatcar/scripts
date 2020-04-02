#!/bin/bash

set -euo pipefail

branch="runc-${VERSION_NEW}"

git -C ~/flatcar-sdk/src/scripts checkout -B "${BASE_BRANCH}" "github/${BASE_BRANCH}"
git -C ~/flatcar-sdk/src/third_party/portage-stable checkout -B "${BASE_BRANCH}" "github/${BASE_BRANCH}"

pushd ~/flatcar-sdk/src/third_party/coreos-overlay >/dev/null || exit
git checkout -B "${branch}" "github/${BASE_BRANCH}"

# Get the original runc version, including official releases and rc versions.
# We need some sed tweaks like adding underscore, sort, and trim the underscore again,
# so that sort -V can give the newest version including non-rc versions.
VERSION_OLD=$(sed -n "s/^DIST docker-runc-\([0-9]*.[0-9]*.*\)\.tar.*/\1/p" app-emulation/docker-runc/Manifest | sed '/-/!{s/$/_/}' | sort -ruV | sed 's/_$//' | head -n1 | tr '-' '_')
[[ "${VERSION_NEW}" = "${VERSION_OLD}" ]] && echo "already the latest Runc, nothing to do" && exit

runcEbuildOld=$(ls -1 app-emulation/docker-runc/docker-runc-${VERSION_OLD}*.ebuild | sort -ruV | head -n1)
runcEbuildNew="app-emulation/docker-runc/docker-runc-${VERSION_NEW}.ebuild"
git mv ${runcEbuildOld} ${runcEbuildNew}
sed -i "s/${VERSION_OLD}/${VERSION_NEW}/g" ${runcEbuildNew}

# update also runc versions used by docker and containerd
sed -i "s/docker-runc-${VERSION_OLD}/docker-runc-${VERSION_NEW}/g" app-emulation/docker/docker-9999.ebuild
sed -i "s/docker-runc-${VERSION_OLD}/docker-runc-${VERSION_NEW}/g" app-emulation/containerd/containerd-9999.ebuild

dockerVersion=$(sed -n "s/^DIST docker-\([0-9]*.[0-9]*.[0-9]*\).*/\1/p" app-emulation/docker/Manifest | sort -ruV | head -n1)

# torcx ebuild file has a docker version with only major and minor versions, like 19.03.
versionTorcx=${dockerVersion%.*}
torcxEbuildFile=$(ls -1 app-torcx/docker/docker-${versionTorcx}*.ebuild | sort -ruV | head -n1)
sed -i "s/docker-runc-${VERSION_OLD}/docker-runc-${VERSION_NEW}/g" ${torcxEbuildFile}

function enter() ( cd ../../..; exec cork enter -- $@ )

# Update manifest and regenerate metadata
enter ebuild "/mnt/host/source/src/third_party/coreos-overlay/app-emulation/docker-runc/docker-runc-${VERSION_NEW}.ebuild" manifest --force

# We can only create the actual commit in the actual source directory, not under the SDK.
# So create a format-patch, and apply to the actual source.
git add app-emulation/docker-runc/docker-runc-${VERSION_NEW}* app-torcx metadata
git commit -a -m "app-emulation/docker-runc: Upgrade Runc ${VERSION_OLD} to ${VERSION_NEW}"

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
