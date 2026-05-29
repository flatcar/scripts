# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Utility for building standalone sysext images.
# Sourced by build_standalone_sysexts (inside the SDK container) and
# called from build_rpm_image.sh via run_sdk_container.
#
# Required globals (set by common.sh):
#   SCRIPT_ROOT, BUILD_LIBRARY_DIR, BOARD
#
# Required environment:
#   STANDALONE_SYSEXTS_SPEC  — space-separated "name|category/package[&pkg]" entries
#
# Optional environment:
#   SYSEXT_COMPRESSION       — override default sysext compression (zstd)
#   PACKAGE_SOURCE_MODE      — "RPM" to pass RPM env vars to build_sysext
#   RPM_STAGING_DIR, IMAGE_VERSION, IMAGE_VERSION_ID, IMAGE_BUILD_ID

# Internal helper: parse sysexts.yaml, filtering by mode, arch, and
# optional tag(s).  Emits "name|pkg1&pkg2" tokens.
#
# Usage:
#   _parse_sysexts_yaml "/path/to/yaml" "amd64-usr" "standalone" " " ""
#   _parse_sysexts_yaml "/path/to/yaml" "amd64-usr" "standalone" " " "kola"
#   _parse_sysexts_yaml "/path/to/yaml" "amd64-usr" "standalone" " " "kola,gpu"
#   _parse_sysexts_yaml "/path/to/yaml" "amd64-usr" "embedded" "," ""
#
# Arguments:
#   $1  yaml_file       — path to the YAML config
#   $2  board           — board name (e.g. "amd64-usr"); mapped to arch
#   $3  mode            — "standalone" or "embedded"
#   $4  separator       — output separator between entries (space or comma)
#   $5  tag_filter      — (optional) comma-separated tags; ignored for embedded
#
# Requires: yq v4 (https://github.com/mikefarah/yq/)
_parse_sysexts_yaml() {
    local yaml_file="$1"
    local board="$2"
    local mode="$3"
    local separator="$4"
    local tag_filter="${5:-}"
    local arch="${board%%-*}"

    if [[ ! -f "${yaml_file}" ]]; then
        echo ""
        return 0
    fi

    # Build the tag filter clause for yq.
    # Tags are only applied for standalone mode.
    local tag_select=""
    local tag_vals=""
    if [[ "${mode}" == "standalone" && -n "${tag_filter}" ]]; then
        tag_vals="${tag_filter}"
        tag_select='| select(.tags != null and ([.tags[] | select(. as $t | env(TAGVALS) | split(",") | map(sub("^\\s+","") | sub("\\s+$","")) | .[] | select(. == $t))] | length > 0))'
    fi

    # Mode filter: match entries with the requested mode.
    # The mode field is required — entries without it are rejected below.
    local mode_select=""
    if [[ "${mode}" == "embedded" ]]; then
        mode_select='| select(.mode == "embedded")'
    else
        mode_select='| select(.mode == "standalone")'
    fi

    # Validate that every entry has a valid mode value.
    local invalid_modes
    if ! invalid_modes=$(yq eval -r '
        .sysexts[] | select(.mode == null or (.mode != "embedded" and .mode != "standalone")) | .name + ": " + (.mode // "missing")
    ' "${yaml_file}"); then
        echo "ERROR: Failed to parse ${yaml_file}:" >&2
        return 1
    fi
    if [[ -n "${invalid_modes}" ]]; then
        echo "ERROR: Invalid or missing mode value(s) in ${yaml_file}:" >&2
        echo "${invalid_modes}" >&2
        return 1
    fi

    local result
    result=$(ARCHVAL="${arch}" TAGVALS="${tag_vals}" \
    yq eval -r "
        .sysexts[]
        ${mode_select}
        | select(.archs == null or (.archs[] | select(. == env(ARCHVAL))))
        ${tag_select}
        | .name + \"|\" + ([.packages[]
            | select(tag == \"!!str\" or .archs == null or (.archs[] | select(. == env(ARCHVAL))))
            | (select(tag == \"!!str\") // .name)]
            | join(\"&\"))
    " "${yaml_file}")

    if [[ "${separator}" == " " ]]; then
        echo "${result}" | tr '\n' ' '
    else
        echo "${result}" | paste -sd "${separator}" -
    fi
}

# Parse sysexts.yaml and emit a space-separated STANDALONE_SYSEXTS_SPEC
# string filtered for the given board and optional tag(s).  Entries without an
# 'archs' key are included for every board.  When a tag filter is given,
# only entries whose 'tags' list contains at least one of the given tags are
# emitted; entries without a 'tags' key are skipped.
#
# Only entries with mode "standalone" (or no mode field) are included.
#
# Usage:
#   spec=$(parse_standalone_sysexts_yaml "/path/to/sysexts.yaml" "amd64-usr")
#   spec=$(parse_standalone_sysexts_yaml "/path/to/sysexts.yaml" "amd64-usr" "kola")
#   spec=$(parse_standalone_sysexts_yaml "/path/to/sysexts.yaml" "amd64-usr" "kola,gpu")
#
# The board name (e.g. "amd64-usr") is mapped to an arch (e.g. "amd64")
# to match the 'archs' values in the YAML.
#
# Output format (one token per sysext, space-separated):
#   name|pkg1&pkg2
#
# Package names can be RPM names or portage-style category/package names.
# In RPM mode, rpm_install_package_using_portage_name() will try each name
# as a direct RPM first, then fall back to the catalog.
#
# Requires: yq v4 (https://github.com/mikefarah/yq/)
parse_standalone_sysexts_yaml() {
    local yaml_file="$1"
    local board="$2"
    local tag_filter="${3:-}"
    _parse_sysexts_yaml "${yaml_file}" "${board}" "standalone" " " "${tag_filter}"
}

# Parse sysexts.yaml and emit a comma-separated list of embedded
# sysext specs for the given board.  These are passed to build_image via
# --base_sysexts.  Tag filtering is not applied to embedded sysexts.
#
# Usage:
#   base_sysexts=$(parse_embedded_sysexts_yaml "/path/to/sysexts.yaml" "amd64-usr")
#
# Output format (comma-separated):
#   name|pkg1&pkg2,name2|pkg3
#
# Requires: yq v4 (https://github.com/mikefarah/yq/)
parse_embedded_sysexts_yaml() {
    local yaml_file="$1"
    local board="$2"
    _parse_sysexts_yaml "${yaml_file}" "${board}" "embedded" "," ""
}

# Build standalone sysext .raw images from STANDALONE_SYSEXTS_SPEC.
#
# Arguments:
#   $1  squashfs_base — path to the sysext base squashfs image
#   $2  output_dir    — directory for intermediate builds and final artifacts
#
# The function is a no-op when STANDALONE_SYSEXTS_SPEC is empty.
build_standalone_sysext_images() {
    local squashfs_base="$1"
    local output_dir="$2"

    if [[ -z "${STANDALONE_SYSEXTS_SPEC:-}" ]]; then
        return 0
    fi

    local compression_opt=""
    if [[ -n "${SYSEXT_COMPRESSION:-}" ]]; then
        compression_opt="--compression=${SYSEXT_COMPRESSION}"
    fi

    # For RPM mode, set environment variables to pass to build_sysext
    local -a build_sysext_env=()
    if [[ "${PACKAGE_SOURCE_MODE:-}" == "RPM" ]]; then
        build_sysext_env=(
            "PACKAGE_SOURCE_MODE=${PACKAGE_SOURCE_MODE}"
            "RPM_STAGING_DIR=${RPM_STAGING_DIR:-}"
            "IMAGE_VERSION=${IMAGE_VERSION:-}"
            "IMAGE_VERSION_ID=${IMAGE_VERSION_ID:-}"
            "IMAGE_BUILD_ID=${IMAGE_BUILD_ID:-}"
        )
    fi

    local sysext_spec
    for sysext_spec in ${STANDALONE_SYSEXTS_SPEC}; do
        local name="${sysext_spec%%|*}"
        local packages="${sysext_spec#*|}"
        info "Building standalone sysext: ${name} (${packages//&/, })"

        # Expand multi-package separator & → individual package args
        local -a pkg_args=()
        IFS='&' read -ra pkg_args <<< "$packages"

        local built_sysext_dir="${output_dir}/${name}-sysext"
        mkdir -p "${built_sysext_dir}"

        local -a sysext_flags=(
            --board="${BOARD}"
            --squashfs_base="${squashfs_base}"
            --image_builddir="${built_sysext_dir}"
            --install_root_basename="${name}-standalone-sysext-rootfs"
            ${compression_opt}
        )

        # Use mangle script if one exists under build_library/
        # (try rpm/sysext/ first, then top-level, then legacy -flatcar suffix)
        local mangle_fs=""
        if [[ -x "${BUILD_LIBRARY_DIR}/rpm/sysext/sysext_mangle_${name}" ]]; then
            mangle_fs="${BUILD_LIBRARY_DIR}/rpm/sysext/sysext_mangle_${name}"
        elif [[ -x "${BUILD_LIBRARY_DIR}/sysext_mangle_${name}" ]]; then
            mangle_fs="${BUILD_LIBRARY_DIR}/sysext_mangle_${name}"
        elif [[ -x "${BUILD_LIBRARY_DIR}/sysext_mangle_${name}-flatcar" ]]; then
            mangle_fs="${BUILD_LIBRARY_DIR}/sysext_mangle_${name}-flatcar"
        fi
        if [[ -n "${mangle_fs}" ]]; then
            sysext_flags+=(
                --manglefs_script="${mangle_fs}"
            )
        fi

        # Sysext name + packages as positional args
        sysext_flags+=("${name}" "${pkg_args[@]}")

        sudo "${build_sysext_env[@]}" "${SCRIPT_ROOT}/build_sysext" "${sysext_flags[@]}"

        # Move sysext artifacts to output directory
        local to_move
        for to_move in "${built_sysext_dir}/${name}"*; do
            [[ -e "${to_move}" ]] && mv -f "${to_move}" "${output_dir}/${to_move##*/}"
        done

        # Clean up work directory
        rm -rf "${built_sysext_dir}"
        info "Built standalone sysext: ${output_dir}/${name}.raw"
    done
}
