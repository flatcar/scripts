#!/bin/bash

set -euo pipefail

. .github/workflows/common.sh

checkout_branches "go-${VERSION_NEW}"

pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit

VERSION_OLD=$(sed -n "s/^DIST go\(${GO_VERSION}.[0-9]*\).*/\1/p" dev-lang/go/Manifest | sort -ruV | head -n1)
[[ "${VERSION_NEW}" = "${VERSION_OLD}" ]] && echo "already the latest Go, nothing to do" && exit

git mv $(ls -1 dev-lang/go/go-${VERSION_OLD}*.ebuild | sort -ruV | head -n1) "dev-lang/go/go-${VERSION_NEW}.ebuild"

popd >/dev/null || exit

generate_patches dev-lang go Go

apply_patches

echo ::set-output name=VERSION_OLD::"${VERSION_OLD}"
