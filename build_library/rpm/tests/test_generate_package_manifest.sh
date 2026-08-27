#!/bin/bash
#
# Check that generate_package_manifest.py emits the expected SPDX 2.2 document.
#
# Usage: test_generate_package_manifest.sh [workdir]

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATOR="${TESTS_DIR}/../generate_package_manifest.py"

# Conformance is a property of the generator, not of any one rootfs, so this is
# run against a fixture instead of inside the image build. This file is a real
# capture from an ACL production image, trimmed, plus one epoch-bearing entry
# and one non-native arch.
NEVRA_PACKAGES_FILE="${TESTS_DIR}/testdata/nevra-packages.txt"

# The same package set as nevra-packages.txt, in `tdnf list installed` layout.
# ACL-T has no rpm binary and feeds the generator this instead, so the two files
# describing one package set is what makes the cross-check below meaningful.
TDNF_PACKAGES_FILE="${TESTS_DIR}/testdata/tdnf-installed.txt"

# When a change to the emitted document is intentional, pass <workdir> to the
# script, copy the normalized output to the golden file, then re-validate it:
#     cp "${WORK_DIR}/package-manifest.spdx.json.normalized" testdata/expected-manifest.spdx.json
#     ./validate_golden_manifest.sh
GOLDEN_FILE="${TESTS_DIR}/testdata/expected-manifest.spdx.json"

# Keep a caller-supplied <workdir> so its output can be inspected, or clean up
# one we made ourselves so we don't leave scratch files behind on a local run.
if [[ $# -ge 1 ]]; then
    WORK_DIR="${1}"
else
    WORK_DIR="$(mktemp -d)"
    trap 'rm -rf "${WORK_DIR}"' EXIT
fi
mkdir -p "${WORK_DIR}"

MANIFEST="${WORK_DIR}/package-manifest.spdx.json"
MANIFEST_AGAIN="${MANIFEST}.again"
MANIFEST_NORMALIZED="${MANIFEST}.normalized"
MANIFEST_TDNF="${MANIFEST}.tdnf"

MANIFEST_NAME="acl_production_image"
MANIFEST_VERSION="0.0.0-spec-conformance"
CREATED_EPOCH=1735689600

echo "=== Generating manifest from ${NEVRA_PACKAGES_FILE##*/} ==="
"${GENERATOR}" \
    --packages-file="${NEVRA_PACKAGES_FILE}" \
    --manifest-file="${MANIFEST}" \
    --manifest-name="${MANIFEST_NAME}" \
    --manifest-version="${MANIFEST_VERSION}" \
    --created-epoch="${CREATED_EPOCH}" \
    --force

echo "=== Checking the generator is byte-identical on a second run ==="
"${GENERATOR}" \
    --packages-file="${NEVRA_PACKAGES_FILE}" \
    --manifest-file="${MANIFEST_AGAIN}" \
    --manifest-name="${MANIFEST_NAME}" \
    --manifest-version="${MANIFEST_VERSION}" \
    --created-epoch="${CREATED_EPOCH}" \
    --force
cmp "${MANIFEST}" "${MANIFEST_AGAIN}"

echo "=== Comparing against ${GOLDEN_FILE##*/} ==="
sed -E 's|("Tool: generate_package_manifest)-[0-9a-f]{64}"|\1"|' \
    "${MANIFEST}" > "${MANIFEST_NORMALIZED}"
diff -u "${GOLDEN_FILE}" "${MANIFEST_NORMALIZED}"

# libstdc++ is the fixture's canary for purl encoding: '+' is outside purl's
# allowed set, so a canonical locator has to carry %2B instead.
EXPECTED_PURL='pkg:rpm/azurelinux/libstdc%2B%2B@13.2.0-7.azl3?arch=x86_64'
echo "=== Checking ${EXPECTED_PURL} is emitted canonically ==="
if ! grep -qF "\"referenceLocator\": \"${EXPECTED_PURL}\"" "${MANIFEST}"; then
    echo "referenceLocator is not the canonical purl: ${EXPECTED_PURL}" >&2
    exit 1
fi

echo "=== Checking --packages-format=tdnf describes the same package set ==="
"${GENERATOR}" \
    --packages-file="${TDNF_PACKAGES_FILE}" \
    --packages-format=tdnf \
    --manifest-file="${MANIFEST_TDNF}" \
    --manifest-name="${MANIFEST_NAME}" \
    --manifest-version="${MANIFEST_VERSION}" \
    --created-epoch="${CREATED_EPOCH}" \
    --force
diff -u "${MANIFEST}" "${MANIFEST_TDNF}"

echo "=== PASS ==="
