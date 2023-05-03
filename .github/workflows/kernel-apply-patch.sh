#!/bin/bash

set -euo pipefail

source "${GHA_SCRIPTS_DIR}/.github/workflows/common.sh"

prepare_git_repo

if ! check_remote_branch "linux-${VERSION_NEW}-${TARGET_BRANCH}"; then
    echo "remote branch already exists, nothing to do"
    exit 0
fi

pushd "${SDK_OUTER_OVERLAY}"

# trim the 3rd part in the input semver, e.g. from 5.4.1 to 5.4
VERSION_SHORT=${VERSION_NEW%.*}
VERSION_OLD=$(sed -n "s/^DIST patch-\(${VERSION_SHORT}\.[0-9]*\).*/\1/p" sys-kernel/coreos-sources/Manifest)
if [[ -z "${VERSION_OLD}" ]]; then
    VERSION_OLD=$(sed -n "s/^DIST linux-\(${VERSION_SHORT}*\).*/\1/p" sys-kernel/coreos-sources/Manifest)
fi
if [[ "${VERSION_NEW}" = "${VERSION_OLD}" ]]; then
    echo "already the latest Kernel, nothing to do"
    exit 0
fi

for pkg in sources modules kernel; do
    pushd "sys-kernel/coreos-${pkg}"
    git mv "coreos-${pkg}"-*.ebuild "coreos-${pkg}-${VERSION_NEW}.ebuild"
    sed -i -e '/^COREOS_SOURCE_REVISION=/s/=.*/=""/' "coreos-${pkg}-${VERSION_NEW}.ebuild"
    popd
done

popd

function get_lwn_link() {
    local LINUX_VERSION="${1}"; shift
    local url

    if ! curl -sfA 'Chrome' -L 'http://www.google.com/search?hl=en&q=site%3Alwn.net+linux+'"${LINUX_VERSION}" -o search.html >&2; then
        echo 'curl failed' >&2
        touch search.html
    fi
    # can't use grep -m 1 -o … to replace head -n 1, because all the links
    # seem to happen in one line, so grep prints all the links in the line
    url=$({ grep -o 'https://lwn.net/Articles/[0-9]\+' search.html || true ; } | head -n 1)
    if [[ ! "${url}" ]]; then
        echo 'no valid links found in the search result' >&2
        url="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tag/?h=v${LINUX_VERSION}"
    fi
    rm search.html
    echo "${url}"
}

PATCH_VERSION_OLD=${VERSION_OLD##*.}
PATCH_VERSION_NEW=${VERSION_NEW##*.}

PATCH_NUM=$((PATCH_VERSION_NEW - 1))

OLD_VERSIONS_AND_URLS=()

while [[ ${PATCH_NUM} -gt ${PATCH_VERSION_OLD} ]]; do
    TMP_VERSION="${VERSION_SHORT}.${PATCH_NUM}"
    TMP_URL=$(get_lwn_link "${TMP_VERSION}")
    OLD_VERSIONS_AND_URLS+=( "${TMP_VERSION}" "${TMP_URL}" )
    : $((PATCH_NUM--))
done

URL=$(get_lwn_link "${VERSION_NEW}")

generate_update_changelog 'Linux' "${VERSION_NEW}" "${URL}" 'linux' "${OLD_VERSIONS_AND_URLS[@]}"

commit_changes sys-kernel/coreos-sources "${VERSION_OLD}" "${VERSION_NEW}" \
               sys-kernel/coreos-modules \
               sys-kernel/coreos-kernel

cleanup_repo

echo "VERSION_OLD=${VERSION_OLD}" >>"${GITHUB_OUTPUT}"
echo 'UPDATE_NEEDED=1' >>"${GITHUB_OUTPUT}"
