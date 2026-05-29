#!/usr/bin/env bash
# Compute a content hash of SDK-relevant source inputs for ACR caching.
#
# This script computes a deterministic hash over the files that affect
# the SDK container build output. The hash is used as an ACR tag to
# enable content-addressed caching — if a container with the same hash
# tag already exists, the 4-6 hour scratch build can be skipped.
#
# The list of hashed paths is defined in acl/sdk-cache/hash-paths.conf.
# A salt value (first line of acl/sdk-cache/cache-version) is mixed in
# so the file's comment block can be edited freely without invalidating
# the cache.
#
# Usage:
#   cd /path/to/azure-container-linux && acl/sdk-cache/compute_sdk_hash.sh
#
# Output (to stdout):
#   SDK_BASE_VERSION: <ver>
#   SDK_CONTENT_HASH: <16-char hex>
#   SDK_CACHE_TAG:    <ver>-rpm.<hash>
# Diagnostics and errors go to stderr.
#
# Sets ADO variables (when running in Azure DevOps):
#   SDK_CONTENT_HASH - the 16-char hash
#   SDK_BASE_VERSION - base SDK version from version.txt (e.g., 4459.0.0)
#   SDK_CACHE_TAG    - full cache tag (e.g., 4459.0.0-rpm.a3f8c2e1b4d7c5a8)
#
# See: acl-pipelines docs/rfcs/sdk-container-caching.md

set -euo pipefail

# Pin locale so `sort` ordering is bytewise-stable across agents.
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HASH_PATHS_CONF="${SCRIPT_DIR}/hash-paths.conf"
CACHE_VERSION_FILE="acl/sdk-cache/cache-version"

cd "${REPO_ROOT}"

if [[ ! -d "sdk_container" ]]; then
    echo "##[error]Must be run from azure-container-linux repo root (sdk_container/ not found)" >&2
    exit 1
fi

if [[ ! -f "${HASH_PATHS_CONF}" ]]; then
    echo "##[error]Hash paths config not found: ${HASH_PATHS_CONF}" >&2
    exit 1
fi

if [[ ! -f "${CACHE_VERSION_FILE}" ]]; then
    echo "##[error]Cache-version file not found: ${CACHE_VERSION_FILE}" >&2
    exit 1
fi

# Read hash paths from config (skip comments, blank lines, strip trailing whitespace).
readarray -t SDK_HASH_PATHS < <(grep -v '^\s*#' "${HASH_PATHS_CONF}" | grep -v '^\s*$' | sed 's/[[:space:]]*$//')

if [[ ${#SDK_HASH_PATHS[@]} -eq 0 ]]; then
    echo "##[error]hash-paths.conf has no entries" >&2
    exit 1
fi

# Read the base SDK version.
# shellcheck source=/dev/null
source sdk_container/.repo/manifests/version.txt
SDK_BASE_VERSION="${FLATCAR_SDK_VERSION:?FLATCAR_SDK_VERSION not set in version.txt}"

# Salt: only the first line of cache-version (the integer) participates
# in the hash. Comments in the file are documentation and must not affect
# the cache key.
CACHE_VERSION_SALT="$(head -n 1 "${CACHE_VERSION_FILE}")"

# Compute content hash over SDK-relevant inputs.
#
# Excluded:
#   - sdk_container/.cache/*  — build cache, not source
#   - cache-version file      — only its first line is salt (mixed in below)
#   - common transient files  — *.pyc, *.swp, *~ (build/editor artifacts)
#
# The salt is concatenated with the file checksums before the final hash so
# that bumping cache-version invalidates the cache without touching files.
SDK_CONTENT_HASH=$(
    {
        find \
            "${SDK_HASH_PATHS[@]}" \
            \( -path 'sdk_container/.cache/*' \
            -o -path "${CACHE_VERSION_FILE}" \
            -o -name '*.pyc' \
            -o -name '*.swp' \
            -o -name '*~' \) -prune \
            -o -type f -print0 \
        | sort -z \
        | xargs -0 sha256sum
        printf 'cache-version-salt:%s\n' "${CACHE_VERSION_SALT}"
    } | sha256sum | cut -c1-16
)

SDK_CACHE_TAG="${SDK_BASE_VERSION}-rpm.${SDK_CONTENT_HASH}"

echo "SDK_BASE_VERSION: ${SDK_BASE_VERSION}"
echo "SDK_CONTENT_HASH: ${SDK_CONTENT_HASH}"
echo "SDK_CACHE_TAG:    ${SDK_CACHE_TAG}"

# Set ADO pipeline variables if running in Azure DevOps
if [[ -n "${BUILD_BUILDID:-}" ]]; then
    echo "##vso[task.setvariable variable=SDK_CONTENT_HASH;isOutput=true]${SDK_CONTENT_HASH}"
    echo "##vso[task.setvariable variable=SDK_BASE_VERSION;isOutput=true]${SDK_BASE_VERSION}"
    echo "##vso[task.setvariable variable=SDK_CACHE_TAG;isOutput=true]${SDK_CACHE_TAG}"
fi
