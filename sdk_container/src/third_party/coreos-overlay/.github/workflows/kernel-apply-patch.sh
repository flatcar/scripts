#!/bin/bash

set -euo pipefail

branch="linux-${VERSION_NEW}"

pushd ~/flatcar-sdk/src/third_party/coreos-overlay || exit
git checkout -B "${branch}" "github/${BASE_BRANCH}"

versionOld=$(sed -n "s/^DIST patch-\(${KERNEL_VERSION}.[0-9]*\).*/\1/p" sys-kernel/coreos-sources/Manifest)
[[ "${VERSION_NEW}" = "$versionOld" ]] && echo "already the latest Kernel, nothing to do" && exit

for pkg in sources modules kernel; do \
  pushd "sys-kernel/coreos-${pkg}" >/dev/null || exit; \
  git mv "coreos-${pkg}"-*.ebuild "coreos-${pkg}-${VERSION_NEW}.ebuild"; \
  sed -i -e '/^COREOS_SOURCE_REVISION=/s/=.*/=""/' "coreos-${pkg}-${VERSION_NEW}.ebuild"; \
  popd >/dev/null || exit; \
done

( cd ../../..; exec cork enter -- ebuild "/mnt/host/source/src/third_party/coreos-overlay/sys-kernel/coreos-sources/coreos-sources-${VERSION_NEW}.ebuild" manifest --force )

# We can only create the actual commit in the actual source directory, not under the SDK.
# So create a format-patch, and apply to the actual source.
git add sys-kernel/coreos-*
git commit -a -m "sys-kernel: Upgrade Linux ${versionOld} to ${VERSION_NEW}"
git format-patch -1 --stdout HEAD > "${branch}".patch
popd || exit

git config user.name 'Flatcar Buildbot'
git config user.email 'buildbot@flatcar-linux.org'
git reset --hard HEAD
git fetch origin
git checkout -B "${BASE_BRANCH}" "origin/${BASE_BRANCH}"
git am ~/flatcar-sdk/src/third_party/coreos-overlay/"${branch}".patch

echo ::set-output name=VERSION_OLD::"${versionOld}"
