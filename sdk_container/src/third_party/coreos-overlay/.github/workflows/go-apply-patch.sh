#!/bin/bash

set -euo pipefail

# trim the 3rd part in the input semver, e.g. from 1.14.3 to 1.14
VERSION_SHORT=${VERSION_NEW%.*}

. .github/workflows/common.sh

checkout_branches "go-${VERSION_NEW}"

pushd "${SDK_OUTER_SRCDIR}/third_party/coreos-overlay" >/dev/null || exit

VERSION_OLD=$(sed -n "s/^DIST go\(${VERSION_SHORT}.[0-9]*\).*/\1/p" dev-lang/go/Manifest | sort -ruV | head -n1)
[[ "${VERSION_NEW}" = "${VERSION_OLD}" ]] && echo "already the latest Go, nothing to do" && exit

git mv $(ls -1 dev-lang/go/go-${VERSION_OLD}*.ebuild | sort -ruV | head -n1) "dev-lang/go/go-${VERSION_NEW}.ebuild"

popd >/dev/null || exit

generate_patches dev-lang go Go

apply_patches

echo ::set-output name=VERSION_OLD::"${VERSION_OLD}"
