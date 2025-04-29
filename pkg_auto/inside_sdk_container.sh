#!/bin/bash

##
## Gathers information about SDK packages and board packages for each
## passed architecture. Also collects info about actual build deps of
## board packages, which may be useful for verifying if SDK provides
## those.
##
## Reports generated:
## sdk-pkgs - contains package information for SDK
## sdk-pkgs-kv - contains package information with key values (USE, PYTHON_TARGETS, CPU_FLAGS_X86) for SDK
## ${arch}-board-pkgs - contains package information for board for chosen architecture
## ${arch}-board-bdeps - contains package information with key values (USE, PYTHON_TARGETS, CPU_FLAGS_X86) of board build dependencies
## sdk-profiles - contains a list of profiles used by the SDK, in evaluation order
## ${arch}-board-profiles - contains a list of profiles used by the board for the chosen architecture, in evaluation order
## sdk-package-repos - contains package information with their repos for SDK
## ${arch}-board-package-repos - contains package information with their repos for board
## sdk-emerge-output - contains raw emerge output for SDK being a base for other reports
## ${arch}-board-emerge-output - contains raw emerge output for board being a base for other reports
## sdk-emerge-output-filtered - contains only lines with package information for SDK
## ${arch}-board-emerge-output-filtered - contains only lines with package information for board
## sdk-emerge-output-junk - contains only junk lines for SDK
## ${arch}-board-emerge-output-junk - contains only junk lines for board
## *-warnings - warnings printed by emerge or other tools
##
## Parameters:
## -h: this help
##
## Positional:
## 1 - reports directory
## # - architectures (currently only amd64 or arm64 are valid)
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/impl/util.sh"
source "${PKG_AUTO_IMPL_DIR}/inside_sdk_container_lib.sh"

while [[ ${#} -gt 0 ]]; do
    case ${1} in
        -h)
            print_help
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            fail "unknown flag '${1}'"
            ;;
        *)
            break
            ;;
    esac
done

if [[ ${#} -lt 2 ]]; then
    fail 'Expected at least two parameters: reports directory and one or more board architectures'
fi

reports_dir=${1}; shift
# rest are architectures

mkdir -p "${reports_dir}"

set_eo "${reports_dir}" "${@}"

echo 'Running egencache for portage-stable'
generate_cache_for 'portage-stable' 2>"${EGENCACHE_W}"
echo 'Running egencache for coreos-overlay'
generate_cache_for 'coreos-overlay' 2>>"${EGENCACHE_W}"

echo 'Copying portage-stable cache to reports'
copy_cache_to_reports 'portage-stable' "${reports_dir}" 2>>"${EGENCACHE_W}"
echo 'Copying coreos-overlay cache to reports'
copy_cache_to_reports 'coreos-overlay' "${reports_dir}" 2>>"${EGENCACHE_W}"

echo 'Running pretend-emerge to get complete report for SDK'
package_info_for_sdk >"${SDK_EO}" 2>"${SDK_EO_W}"
for arch; do
    be=${arch^^}_BOARD_EO
    bew=${arch^^}_BOARD_EO_W
    echo "Running pretend-emerge to get complete report for ${arch} board"
    package_info_for_board "${arch}" >"${!be}" 2>"${!bew}"
done

ensure_no_errors "${@}"

echo 'Separating emerge info from junk in SDK emerge output'
filter_sdk_eo >"${SDK_EO_F}" 2>>"${SDK_EO_W}"
junk_sdk_eo >"${SDK_EO_J}" 2>>"${SDK_EO_W}"
for arch; do
    bej=${arch^^}_BOARD_EO_J
    bef=${arch^^}_BOARD_EO_F
    bew=${arch^^}_BOARD_EO_W
    echo "Separating emerge info from junk in ${arch} board emerge output"
    filter_board_eo "${arch}" >"${!bef}" 2>>"${!bew}"
    junk_board_eo "${arch}" >"${!bej}" 2>>"${!bew}"
done

ensure_valid_reports "${@}"

echo 'Generating SDK packages listing'
versions_sdk >"${reports_dir}/sdk-pkgs" 2>"${reports_dir}/sdk-pkgs-warnings"
echo 'Generating SDK packages listing with key-values (USE, PYTHON_TARGETS CPU_FLAGS_X86, etc)'
versions_sdk_with_key_values >"${reports_dir}/sdk-pkgs-kv" 2>"${reports_dir}/sdk-pkgs-kv-warnings"
echo 'Generating SDK profiles evaluation list'
ROOT=/ "${PKG_AUTO_IMPL_DIR}/print_profile_tree.sh" -ni -nh >"${reports_dir}/sdk-profiles" 2>"${reports_dir}/sdk-profiles-warnings"
echo 'Generating SDK package source information'
package_sources_sdk >"${reports_dir}/sdk-package-repos" 2>"${reports_dir}/sdk-package-repos-warnings"

for arch; do
    echo "Generating ${arch} board packages listing"
    versions_board "${arch}" >"${reports_dir}/${arch}-board-pkgs" 2>"${reports_dir}/${arch}-board-pkgs-warnings"
    echo "Generating ${arch} board packages bdeps listing"
    board_bdeps "${arch}" >"${reports_dir}/${arch}-board-bdeps" 2>"${reports_dir}/${arch}-board-bdeps-warnings"
    echo "Generating ${arch} board profiles evaluation list"
    ROOT="/build/${arch}-usr" "${PKG_AUTO_IMPL_DIR}/print_profile_tree.sh" -ni -nh >"${reports_dir}/${arch}-board-profiles" 2>"${reports_dir}/${arch}-board-profiles-warnings"
    echo "Generating ${arch} board package source information"
    package_sources_board "${arch}" >"${reports_dir}/${arch}-board-package-repos" 2>"${reports_dir}/${arch}-board-package-repos-warnings"
done

echo "Cleaning empty warning files"
clean_empty_warning_files "${reports_dir}"
