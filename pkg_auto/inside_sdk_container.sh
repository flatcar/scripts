#!/bin/bash

##
## Gathers information about SDK and board packages. Also collects
## info about actual build deps of board packages, which may be useful
## for verifying if SDK provides those.
##
## Reports generated:
## sdk-pkgs - contains package information for SDK
## sdk-pkgs-kv - contains package information with key values (USE, PYTHON_TARGETS, CPU_FLAGS_X86) for SDK
## board-pkgs - contains package information for board for chosen architecture
## board-bdeps - contains package information with key values (USE, PYTHON_TARGETS, CPU_FLAGS_X86) of board build dependencies
## sdk-profiles - contains a list of profiles used by the SDK, in evaluation order
## board-profiles - contains a list of profiles used by the board for the chosen architecture, in evaluation order
## sdk-package-repos - contains package information with their repos for SDK
## board-package-repos - contains package information with their repos for board
## sdk-emerge-output - contains raw emerge output for SDK being a base for other reports
## board-emerge-output - contains raw emerge output for board being a base for other reports
## sdk-emerge-output-filtered - contains only lines with package information for SDK
## board-emerge-output-filtered - contains only lines with package information for board
## sdk-emerge-output-junk - contains only junk lines for SDK
## board-emerge-output-junk - contains only junk lines for board
## *-warnings - warnings printed by emerge or other tools
##
## Parameters:
## -h: this help
##
## Positional:
## 1 - architecture (amd64 or arm64)
## 2 - reports directory
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"
source "${PKG_AUTO_DIR}/inside_sdk_container_lib.sh"

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

if [[ ${#} -ne 2 ]]; then
    fail 'Expected two parameters: board architecture and reports directory'
fi

arch=${1}; shift
reports_dir=${1}; shift

mkdir -p "${reports_dir}"

set_eo "${reports_dir}"

echo 'Running pretend-emerge to get complete report for SDK'
package_info_for_sdk >"${SDK_EO}" 2>"${SDK_EO_W}"
echo 'Running pretend-emerge to get complete report for board'
package_info_for_board "${arch}" >"${BOARD_EO}" 2>"${BOARD_EO_W}"

ensure_no_errors

echo 'Separating emerge info from junk in SDK emerge output'
filter_sdk_eo >"${SDK_EO_F}" 2>>"${SDK_EO_W}"
junk_sdk_eo >"${SDK_EO}-junk" 2>>"${SDK_EO_W}"
echo 'Separating emerge info from junk in board emerge output'
filter_board_eo "${arch}" >"${BOARD_EO_F}" 2>>"${BOARD_EO_W}"
junk_board_eo >"${BOARD_EO}-junk" 2>>"${BOARD_EO_W}"

ensure_valid_reports

echo 'Generating SDK packages listing'
versions_sdk >"${reports_dir}/sdk-pkgs" 2>"${reports_dir}/sdk-pkgs-warnings"
echo 'Generating SDK packages listing with key-values (USE, PYTHON_TARGETS CPU_FLAGS_X86, etc)'
versions_sdk_with_key_values >"${reports_dir}/sdk-pkgs-kv" 2>"${reports_dir}/sdk-pkgs-kv-warnings"
echo 'Generating board packages listing'
versions_board >"${reports_dir}/board-pkgs" 2>"${reports_dir}/board-pkgs-warnings"
echo 'Generating board packages bdeps listing'
board_bdeps >"${reports_dir}/board-bdeps" 2>"${reports_dir}/board-bdeps-warnings"
echo 'Generating SDK profiles evaluation list'
ROOT=/ "${PKG_AUTO_DIR}/print_profile_tree.sh" -ni -nh >"${reports_dir}/sdk-profiles" 2>"${reports_dir}/sdk-profiles-warnings"
echo 'Generating board profiles evaluation list'
ROOT="/build/${arch}-usr" "${PKG_AUTO_DIR}/print_profile_tree.sh" -ni -nh >"${reports_dir}/board-profiles" 2>"${reports_dir}/board-profiles-warnings"
echo 'Generating SDK package source information'
package_sources_sdk >"${reports_dir}/sdk-package-repos" 2>"${reports_dir}/sdk-package-repos-warnings"
echo 'Generating board package source information'
package_sources_board >"${reports_dir}/board-package-repos" 2>"${reports_dir}/board-package-repos-warnings"

echo "Cleaning empty warning files"
clean_empty_warning_files "${reports_dir}"
