#!/usr/bin/env bash
# Tests for SDK content-hash caching logic.
#
# Verifies that compute_sdk_hash.sh:
#   - Produces deterministic output
#   - Changes when hashed files change
#   - Does NOT change when non-hashed files change
#   - Responds to cache-version salt bumps
#   - Ignores cache-version comment edits (only first line is salt)
#
# Usage:
#   ./test_sdk_hash.sh
#
# Must be run from inside the azure-container-linux repo (anywhere works).

set -euo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HASH_SCRIPT="${SCRIPT_DIR}/compute_sdk_hash.sh"
HASH_PATHS_CONF="${SCRIPT_DIR}/hash-paths.conf"

cd "${REPO_ROOT}"

PASS=0
FAIL=0
TOUCHED_FILES=()

pass() {
    PASS=$((PASS + 1))
    echo "  ✓ $1"
}

fail() {
    FAIL=$((FAIL + 1))
    echo "  ✗ $1" >&2
}

# Run the hash script once and emit a summary line we can grep.
run_hash() {
    bash "${HASH_SCRIPT}"
}

extract_hash_from() {
    grep '^SDK_CONTENT_HASH:' <<<"$1" | awk '{print $2}'
}

extract_tag_from() {
    grep '^SDK_CACHE_TAG:' <<<"$1" | awk '{print $2}'
}

# ── Mutation helpers (with bookkeeping for trap-based restore) ─────────
modify_file() {
    TOUCHED_FILES+=("$1")
    echo "# test modification $(date +%s%N)" >> "$1"
}

write_file() {
    TOUCHED_FILES+=("$1")
    printf '%s' "$2" > "$1"
}

restore_all() {
    local f
    local rc=0
    for f in "${TOUCHED_FILES[@]:-}"; do
        [[ -z "${f}" ]] && continue
        if ! git checkout -- "${f}" 2>/dev/null; then
            echo "##[error]Failed to restore ${f}; check 'git status'" >&2
            rc=1
        fi
    done
    TOUCHED_FILES=()
    return ${rc}
}

# Always restore on exit, even on failure / Ctrl-C / agent timeout.
trap 'restore_all || true' EXIT INT TERM

# ── Load hashed paths from shared config ───────────────────────────────
readarray -t HASHED_PATHS < <(grep -v '^\s*#' "${HASH_PATHS_CONF}" | grep -v '^\s*$' | sed 's/[[:space:]]*$//')

# Pick a small set of representative files dynamically: one file from each
# path in hash-paths.conf (first found by `find`). Skips the cache-version
# file because it has special-case semantics covered by tests 5 + 6.
HASHED_TEST_FILES=()
for path in "${HASHED_PATHS[@]}"; do
    if [[ -f "${path}" ]]; then
        HASHED_TEST_FILES+=("${path}")
    elif [[ -d "${path}" ]]; then
        f=$(find "${path}" -type f \
            ! -path '*/.cache/*' \
            ! -name 'cache-version' \
            ! -name '*.pyc' ! -name '*.swp' ! -name '*~' \
            -print -quit 2>/dev/null)
        [[ -n "${f}" ]] && HASHED_TEST_FILES+=("${f}")
    fi
done

# ── Non-hashed files (test-only, not shared) ───────────────────────────
# Representative files known to be outside the hash scope.
NON_HASHED_FILES=(
    common.sh
    settings.env
    build_library/prod_image_util.sh
    build_library/build_image_util.sh
    build_library/vm_image_util.sh
)

echo "=== SDK Content Hash Tests ==="
echo ""

# Compute the baseline once and reuse.
BASELINE_OUT="$(run_hash)"
BASELINE=$(extract_hash_from "${BASELINE_OUT}")

# ── Test 1: Determinism ────────────────────────────────────────────────
echo "Test 1: Hash is deterministic"
SECOND_OUT="$(run_hash)"
SECOND=$(extract_hash_from "${SECOND_OUT}")
if [[ "${BASELINE}" == "${SECOND}" && -n "${BASELINE}" ]]; then
    pass "Two runs produce identical hash: ${BASELINE}"
else
    fail "Non-deterministic: '${BASELINE}' vs '${SECOND}'"
fi

# ── Test 2: Hash format ───────────────────────────────────────────────
echo "Test 2: Output format"
TAG=$(extract_tag_from "${BASELINE_OUT}")
if [[ "${TAG}" =~ ^[0-9]+\.[0-9]+\.[0-9]+-rpm\.[a-f0-9]{16}$ ]]; then
    pass "Tag format is valid: ${TAG}"
else
    fail "Unexpected tag format: '${TAG}'"
fi

# ── Test 3: Hashed files cause hash change ─────────────────────────────
echo "Test 3: Changes to hashed files invalidate cache (representative files)"
if [[ ${#HASHED_TEST_FILES[@]} -eq 0 ]]; then
    fail "Could not locate any representative hashed files"
fi
for f in "${HASHED_TEST_FILES[@]}"; do
    modify_file "${f}"
    MODIFIED=$(extract_hash_from "$(run_hash)")
    restore_all
    if [[ "${MODIFIED}" != "${BASELINE}" ]]; then
        pass "Modifying ${f} changed hash"
    else
        fail "Modifying ${f} did NOT change hash"
    fi
done

# ── Test 4: Non-hashed files do NOT cause hash change ──────────────────
echo "Test 4: Changes to non-hashed files do NOT invalidate cache"
for f in "${NON_HASHED_FILES[@]}"; do
    if [[ ! -f "${f}" ]]; then
        fail "Non-hashed file not found: ${f} (skipped)"
        continue
    fi
    modify_file "${f}"
    MODIFIED=$(extract_hash_from "$(run_hash)")
    restore_all
    if [[ "${MODIFIED}" == "${BASELINE}" ]]; then
        pass "Modifying ${f} did NOT change hash"
    else
        fail "Modifying ${f} unexpectedly changed hash"
    fi
done

# ── Test 5: Cache-version salt bump (first line) ───────────────────────
echo "Test 5: Bumping cache-version salt changes hash"
ORIGINAL_SALT=$(head -n 1 acl/sdk-cache/cache-version)
NEW_SALT=$(( ORIGINAL_SALT + 1 ))
# Replace just the first line to mimic a real salt bump.
{ echo "${NEW_SALT}"; tail -n +2 acl/sdk-cache/cache-version; } > acl/sdk-cache/cache-version.tmp
TOUCHED_FILES+=("acl/sdk-cache/cache-version")
mv acl/sdk-cache/cache-version.tmp acl/sdk-cache/cache-version
SALTED=$(extract_hash_from "$(run_hash)")
restore_all
if [[ "${SALTED}" != "${BASELINE}" ]]; then
    pass "Salt bump changed hash"
else
    fail "Salt bump did NOT change hash"
fi

# ── Test 6: cache-version comment edits do NOT change hash ─────────────
echo "Test 6: Editing cache-version comments does NOT invalidate cache"
echo "# extra comment $(date +%s%N)" >> acl/sdk-cache/cache-version
TOUCHED_FILES+=("acl/sdk-cache/cache-version")
COMMENT_HASH=$(extract_hash_from "$(run_hash)")
restore_all
if [[ "${COMMENT_HASH}" == "${BASELINE}" ]]; then
    pass "Appending a comment did NOT change hash"
else
    fail "Appending a comment unexpectedly changed hash"
fi

# ── Test 7: hash-paths.conf is non-empty ───────────────────────────────
echo "Test 7: hash-paths.conf has entries"
if [[ ${#HASHED_PATHS[@]} -gt 0 ]]; then
    pass "hash-paths.conf has ${#HASHED_PATHS[@]} entries"
else
    fail "hash-paths.conf is empty"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
if [[ ${FAIL} -gt 0 ]]; then
    exit 1
fi
