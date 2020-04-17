#!/bin/bash

set -euo pipefail

. .github/workflows/common.sh

checkout_branches "linux-${VERSION_NEW}"

pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit

VERSION_OLD=$(sed -n "s/^DIST patch-\(${KERNEL_VERSION}.[0-9]*\).*/\1/p" sys-kernel/coreos-sources/Manifest)
if [[ -z "${VERSION_OLD}" ]]; then
  VERSION_OLD=$(sed -n "s/^DIST linux-\(${KERNEL_VERSION}*\).*/\1/p" sys-kernel/coreos-sources/Manifest)
fi
[[ "${VERSION_NEW}" = "${VERSION_OLD}" ]] && echo "already the latest Kernel, nothing to do" && exit

for pkg in sources modules kernel; do \
  pushd "sys-kernel/coreos-${pkg}" >/dev/null || exit; \
  git mv "coreos-${pkg}"-*.ebuild "coreos-${pkg}-${VERSION_NEW}.ebuild"; \
  sed -i -e '/^COREOS_SOURCE_REVISION=/s/=.*/=""/' "coreos-${pkg}-${VERSION_NEW}.ebuild"; \
  popd >/dev/null || exit; \
done

popd >/dev/null || exit

generate_patches sys-kernel coreos-{sources,kernel,modules} Linux

apply_patches

echo ::set-output name=VERSION_OLD::"${VERSION_OLD}"
