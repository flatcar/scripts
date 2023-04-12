#!/bin/bash

set -euo pipefail

source "${GHA_SCRIPTS_DIR}/.github/workflows/common.sh"

pushd "${SDK_OUTER_OVERLAY}"

KV=$(git ls-files 'sys-kernel/coreos-kernel/*ebuild' | head -n 1 | cut -d '-' -f 5- | cut -d . -f 1-2)
REMOTE='https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git'
kernelVersion=$(git ls-remote --tags "${REMOTE}" | cut -f2 | sed -n "/refs\/tags\/v${KV}\.[0-9]*$/s/^refs\/tags\/v//p" | sort -ruV | head -1)

popd

echo "KERNEL_VERSION=${kernelVersion}" >>"${GITHUB_OUTPUT}"
