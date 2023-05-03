# Copyright © Microsoft Corporation
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

get_versions_from_equery() {
    local equery_cmd="${1}"
    local pkg="${2}"

    "${equery_cmd}" --quiet --no-color list --format='${version} ${fullversion}' "${pkg}" || :
}

filter_out_too_new() {
    local version="${1}"
    local line
    local other
    local otherfull
    local result

    while read -r line; do
        other=$(echo "${line}" | cut -d' ' -f1)
        otherfull=$(echo "${line}" | cut -d' ' -f2)
        result=$(printf '%s\n%s\n' "${version}" "${other}" | sort --version-sort | head --lines 1)
        if [[ "${result}" != "${version}" ]]; then
            echo "${otherfull}"
        fi
    done
}

# Remove hard blocks using passed emerge and equery commands, and a
# list of packages to be dropped. A package is specified as full
# package name and a version, separated by a colon. All packages with
# this name and with a lower version will be forcibly removed.
#
# Example invocation:
#
# $ remove_hard_blocks \
#       emerge-amd64-usr equery-amd64-usr \
#       dev-python/setuptools_scm:2
remove_hard_blocks() {
    local emerge_cmd="${1}"
    local equery_cmd="${2}"
    local pkg_ver
    local line
    local pkg
    local version
    local -a pkgs_to_drop
    shift 2

    for pkg_ver; do
        pkg=$(echo "${pkg_ver}" | cut -d: -f1)
        version=$(echo "${pkg_ver}" | cut -d: -f2)
        while read -r line; do
            pkgs_to_drop+=("${pkg}-${line}")
        done < <(get_versions_from_equery "${equery_cmd}" "${pkg}" | filter_out_too_new "${version}")
    done
    if [[ ${#pkgs_to_drop[@]} -gt 0 ]]; then
        info "Dropping the following packages to avoid hard blocks: ${pkgs_to_drop[@]}"
        "${emerge_cmd}" --unmerge "${pkgs_to_drop[@]}"
    else
        info "No hard blockers to remove"
    fi
}
