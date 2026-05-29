#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Package catalog — loads Portage→RPM mappings from package_catalog.yaml.
# The YAML file is the source of truth; this script populates the bash
# associative array PACKAGE_CATALOG and provides lookup helpers.
#
# Requires: python3 (no external libraries needed)

_CATALOG_DIR="${BASH_SOURCE[0]%/*}"
_CATALOG_YAML="${_CATALOG_DIR}/package_catalog.yaml"

if [[ ! -f "${_CATALOG_YAML}" ]]; then
    echo "FATAL: package_catalog.yaml not found at ${_CATALOG_YAML}" >&2
    exit 1
fi

# Determine which YAML parser to use
if ! command -v python3 &>/dev/null; then
    echo "FATAL: python3 is required but not found in PATH" >&2
    exit 1
fi

# ── Load the package catalog from YAML ──────────────────────────────────────
#
# Entry formats in YAML:
#   key: scalar          → single RPM name (or SKIP)
#   key: [list]          → multiple RPM names, joined with spaces
#   key: {rpm: …}        → single RPM with optional attributes (e.g. arch)
#   key: {rpm: [], …}    → multiple RPMs with optional attributes
#
# The parser normalises all of these into "key<TAB>rpm_value<TAB>arch_or_null".
declare -gA PACKAGE_CATALOG=()

_board_arch=""
case "${BOARD:-amd64-usr}" in
    arm64-usr) _board_arch="arm64" ;;
    *)         _board_arch="amd64" ;;
esac

# Generate TSV output from YAML using the standalone parser script.
# The parser handles the three entry formats used in the catalog YAML:
#   key: scalar        →  key\tscalar\tnull
#   key:\n  - item     →  key\titem1 item2\tnull
#   key:\n  rpm: ..\n  arch: ..  →  key\trpm\tarch
_catalog_tsv_cmd() {
    local yaml_file="$1"
    python3 "${_CATALOG_DIR}/parse_catalog.py" "$yaml_file"
}

while IFS=$'\t' read -r key value arch; do
    [[ -z "$key" ]] && continue
    # Apply architecture filter: if the entry has an arch restriction and
    # it doesn't match the current board, mark it SKIP.
    if [[ -n "$arch" && "$arch" != "null" && "$arch" != "$_board_arch" ]]; then
        PACKAGE_CATALOG["$key"]="SKIP"
    else
        PACKAGE_CATALOG["$key"]="$value"
    fi
done < <(_catalog_tsv_cmd "${_CATALOG_YAML}")

unset _board_arch

# ── Helper functions ────────────────────────────────────────────────────────

# Apply architecture filter: mark arch-incompatible packages as SKIP.
# This is handled automatically during YAML loading above, but callers
# may invoke this to re-apply after modifying the catalog at runtime.
catalog_filter_by_arch() {
    local board="${1:-${BOARD:-amd64-usr}}"
    local target_arch=""
    case "${board}" in
        arm64-usr) target_arch="arm64" ;;
        *)         target_arch="amd64" ;;
    esac

    # Re-read arch constraints from YAML and apply
    local _key _arch
    while IFS=$'\t' read -r _key _ _arch; do
        [[ -z "$_key" ]] && continue
        if [[ -n "$_arch" && "$_arch" != "null" && "$_arch" != "$target_arch" ]]; then
            PACKAGE_CATALOG["$_key"]="SKIP"
        fi
    done < <(_catalog_tsv_cmd "${_CATALOG_YAML}")
}

# Get RPM package name from Portage package name
get_rpm_package_name() {
    local portage_pkg="$1"

    # Check if package exists in catalog
    if [[ ! -v "PACKAGE_CATALOG[$portage_pkg]" ]]; then
        return 1
    fi

    local rpm_name="${PACKAGE_CATALOG[$portage_pkg]}"

    if [[ -z "$rpm_name" ]]; then
        return 1
    fi

    # Check if it's actually a valid RPM name (not SKIP)
    if [[ "$rpm_name" == "SKIP" ]]; then
        return 1
    fi

    echo "$rpm_name"
}

# Get package status from catalog
get_package_status() {
    local portage_pkg="$1"

    # Check if package exists in catalog
    if [[ ! -v "PACKAGE_CATALOG[$portage_pkg]" ]]; then
        echo "UNKNOWN"
        return
    fi

    local value="${PACKAGE_CATALOG[$portage_pkg]}"

    if [[ -z "$value" ]]; then
        echo "UNKNOWN"
        return
    fi

    # If value is SKIP, return SKIP status, otherwise RPM
    if [[ "$value" == "SKIP" ]]; then
        echo "SKIP"
    else
        echo "RPM"
    fi
}

# Export functions
export -f get_rpm_package_name
export -f get_package_status
