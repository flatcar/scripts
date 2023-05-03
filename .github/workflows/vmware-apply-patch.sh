#!/bin/bash

set -euo pipefail

source "${GHA_SCRIPTS_DIR}/.github/workflows/common.sh"

prepare_git_repo

if ! check_remote_branch "open-vm-tools-${VERSION_NEW}-${TARGET_BRANCH}"; then
    echo "remote branch already exists, nothing to do"
    exit 0
fi

# Update app-emulation/open-vm-tools

pushd "${SDK_OUTER_OVERLAY}"

# Parse the Manifest file for already present source files and keep the latest version in the current series
VERSION_OLD=$(sed -n "s/^DIST open-vm-tools-\([0-9]*\.[0-9]*\.[0-9]*\).*$/\1/p" app-emulation/open-vm-tools/Manifest | sort -ruV | head -n1)
if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
    echo "already the latest open-vm-tools, nothing to do"
    exit 0
fi

EBUILD_FILENAME_OVT=$(get_ebuild_filename app-emulation/open-vm-tools "${VERSION_OLD}")
git mv "${EBUILD_FILENAME_OVT}" "app-emulation/open-vm-tools/open-vm-tools-${VERSION_NEW}.ebuild"

# We need to also replace the old build number with the new build number in the ebuild.
sed -i -e "s/^\(MY_P=.*-\)[0-9]*\"$/\1${BUILD_NUMBER}\"/" "app-emulation/open-vm-tools/open-vm-tools-${VERSION_NEW}.ebuild"

# Also update coreos-base/oem-vmware
EBUILD_FILENAME_OEM=$(get_ebuild_filename coreos-base/oem-vmware "${VERSION_OLD}")
git mv "${EBUILD_FILENAME_OEM}" "coreos-base/oem-vmware/oem-vmware-${VERSION_NEW}.ebuild"

popd

URL="https://github.com/vmware/open-vm-tools/releases/tag/stable-${VERSION_NEW}"

generate_update_changelog 'open-vm-tools' "${VERSION_NEW}" "${URL}" 'open-vm-tools'

commit_changes app-emulation/open-vm-tools "${VERSION_OLD}" "${VERSION_NEW}" \
               coreos-base/oem-vmware

cleanup_repo

echo "VERSION_OLD=${VERSION_OLD}" >>"${GITHUB_OUTPUT}"
echo 'UPDATE_NEEDED=1' >>"${GITHUB_OUTPUT}"
