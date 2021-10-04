#!/bin/bash

set -euo pipefail

UPDATE_NEEDED=1

. .github/workflows/common.sh

prepare_git_repo

if ! checkout_branches "${VERSION_NEW}-${TARGET}"; then
  UPDATE_NEEDED=0
  exit 0
fi

# Update app-emulation/open-vm-tools

pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit

# Parse the Manifest file for already present source files and keep the latest version in the current series
VERSION_OLD=$(sed -n "s/^DIST open-vm-tools-\([0-9]*\.[0-9]*\.[0-9]*\).*$/\1/p" app-emulation/open-vm-tools/Manifest | sort -ruV | head -n1)
if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
  echo "already the latest open-vm-tools, nothing to do"
  UPDATE_NEEDED=0
  exit 0
fi

EBUILD_FILENAME_OVT=$(get_ebuild_filename "app-emulation" "open-vm-tools" "${VERSION_OLD}")
git mv "${EBUILD_FILENAME_OVT}" "app-emulation/open-vm-tools/open-vm-tools-${VERSION_NEW}.ebuild"

# We need to also replace the old build number with the new build number in the ebuild.
sed -i -e "s/^\(MY_P=.*-\)[0-9]*\"$/\1${BUILD_NUMBER}\"/" app-emulation/open-vm-tools/open-vm-tools-${VERSION_NEW}.ebuild

popd >/dev/null || exit

generate_patches app-emulation open-vm-tools open-vm-tools

apply_patches


# Update coreos-base/oem-vmware

pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit

EBUILD_FILENAME_OEM=$(get_ebuild_filename "coreos-base" "oem-vmware" "${VERSION_OLD}")
git mv "${EBUILD_FILENAME_OEM}" "coreos-base/oem-vmware/oem-vmware-${VERSION_NEW}.ebuild"

popd >/dev/null || exit

generate_patches coreos-base oem-vmware oem-vmware

apply_patches

echo ::set-output name=VERSION_OLD::"${VERSION_OLD}"
echo ::set-output name=UPDATE_NEEDED::"${UPDATE_NEEDED}"
