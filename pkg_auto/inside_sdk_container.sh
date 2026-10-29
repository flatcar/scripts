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
## ${arch}-board-pkgs - contains package information of a board with chosen architecture
## ${arch}-board-pkgs-kv - contains package information with key values (USE, PYTHON_TARGETS, CPU_FLAGS_X86) of a board with chosen architecture
## ${arch}-board-bdeps - contains package information with key values (USE, PYTHON_TARGETS, CPU_FLAGS_X86, etc) of a board (with chosen architecture) build dependencies
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
## -d: debug output
##
## Positional:
## 1 - reports directory
## # - architectures (currently only amd64 or arm64 are valid)
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/impl/util.sh"
source "${PKG_AUTO_IMPL_DIR}/inside_sdk_container_lib.sh"

debug_args=()
debug=''

while [[ ${#} -gt 0 ]]; do
    case ${1} in
        '-d')
            debug_args=(-d)
            debug=x
            shift
            ;;
        '-h')
            print_help
            exit 0
            ;;
        '--')
            shift
            break
            ;;
        '-'*)
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

timeinfo=''

if [[ -n ${debug} ]]; then
    set -x
fi

sdk_type='new'
main_repo='gentoo'
repo_config=$(cat /etc/portage/repos.conf/*)
if grep -qF 'portage-stable' <<<"${repo_config}"; then
    sdk_type='old'
    main_repo='portage-stable'
fi
repos_type='new'
ps=${PKG_AUTO_DIR}/../sdk_container/src/third_party/portage-stable
if [[ -d ${ps} && ! -L ${ps} ]]; then
    repos_type='old'
fi

if [[ -n ${debug} ]]; then
    trap_cmds=('printf "  - %s\n" "${trap_cmds[@]}"; set -x;')
else
    trap_cmds=(':;')
fi

case "${sdk_type} sdk, ${repos_type} repos" in
    'old sdk, old repos'|'new sdk, new repos')
        : # nothing to do
        ;;
    'old sdk, new repos')
        # fake gentoo as portage-stable
        g=${PKG_AUTO_DIR}/../sdk_container/src/third_party/gentoo
        ln -sf gentoo "${ps}"
        trap_cmds+=("rm -f ${ps@Q};")
        # temporarily rename gentoo to portage-stable
        gprn=${g}/profiles/repo_name
        mv "${gprn}"{,.bak}
        echo portage-stable >"${gprn}"
        trap_cmds+=("rm -f ${gprn@Q}; mv ${gprn@Q}{.bak,};")
        # temporarily modify overlay metadata to mention portage-stable as master
        o=${PKG_AUTO_DIR}/../sdk_container/src/third_party/coreos-overlay
        olc=${o}/metadata/layout.conf
        mv "${olc}"{,.bak}
        sed -e 's/masters[[:space:]]*=[[:space:]]*gentoo/masters = portage-stable/' "${olc}.bak" >"${olc}"
        trap_cmds+=("rm -f ${olc@Q}; mv ${olc@Q}{.bak,};")
        # temporarily rename gentoo to portage-stable in overlay profiles
        for parent in $(grep -F 'gentoo:' $(find "${o}/profiles" -name parent) | cut -f1 -d: | sort -u); do
            mv "${parent}"{,.bak}
            sed -e 's/gentoo:/portage-stable:/' "${parent}.bak" >"${parent}"
            trap_cmds+=("rm -f ${parent@Q}; mv ${parent@Q}{.bak,};")
        done
        unset parent olc o gprn g
        ;;
    'new sdk, old repos') # new sdk, old repos
        fail "Just use old SDK for old repos"
        ;;
    *)
        fail "Bad case '${sdk_type} sdk, ${repos_type} repos'"
        ;;
esac

unset ps

if [[ -n ${debug} ]]; then
    trap_cmds+=("set +x;")
fi

if [[ ${repos_type} = 'new' ]]; then
    echo "Prioritising overlay over main repo"
    co="${PKG_AUTO_DIR}"/../sdk_container/src/third_party/coreos-overlay
    conf="/etc/portage/package.mask/pkg-auto-coreos-overlay-over-${main_repo}.conf"
    trap_cmds+=( "sudo rm -f ${conf@Q}" )
    for pkg in "${co}"/*-*/*/ "${co}"/virtual/*/; do
        pkg=${pkg#"${co}"/}
        echo "${pkg%/}::${main_repo}"
    done >"${reports_dir}/mask.conf"
    sudo mv "${reports_dir}/mask.conf" "${conf}"
    for arch; do
        board_conf=/build/${arch}-usr${conf}
        sudo mkdir -p "${board_conf%/*}"
        sudo ln -snf "${conf}" "${board_conf}"
        trap_cmds+=( "sudo rm -f ${board_conf@Q}" )
    done
    unset pkg co arch board_conf conf
fi

trap "${trap_cmds[*]}" EXIT

if [[ -n ${debug} ]]; then
    set +x
fi

echo "Running egencache for ${main_repo}"
timed_run timeinfo generate_cache_for "${debug_args[@]}" "${main_repo}" 2>"${EGENCACHE_W}"
echo "Running egencache for ${main_repo} took ${timeinfo}"
echo 'Running egencache for coreos-overlay'
timed_run timeinfo generate_cache_for "${debug_args[@]}" 'coreos-overlay' 2>>"${EGENCACHE_W}"
echo "Running egencache for coreos-overlay took ${timeinfo}"

echo 'Copying gentoo cache to reports'
copy_cache_to_reports "${debug_args[@]}" "${main_repo}" "${reports_dir}" 2>>"${EGENCACHE_W}"
echo 'Copying coreos-overlay cache to reports'
copy_cache_to_reports "${debug_args[@]}" 'coreos-overlay' "${reports_dir}" 2>>"${EGENCACHE_W}"

echo 'Running pretend-emerge to get complete report for SDK'
timed_run timeinfo package_info_for_sdk "${debug_args[@]}" "${SDK_EO}" 2>"${SDK_EO_W}"
echo "Running pretend-emerge to get complete report for SDK took ${timeinfo}"
for arch; do
    be=${arch^^}_BOARD_EO
    bew=${arch^^}_BOARD_EO_W
    echo "Running pretend-emerge to get complete report for ${arch} board"
    timed_run timeinfo package_info_for_board "${debug_args[@]}" "${arch}" "${!be}" 2>"${!bew}"
    echo "Running pretend-emerge to get complete report for ${arch} board took ${timeinfo}"
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
echo 'Generating SDK packages listing with key-values (USE, PYTHON_TARGETS, CPU_FLAGS_X86, etc)'
versions_sdk_with_key_values >"${reports_dir}/sdk-pkgs-kv" 2>"${reports_dir}/sdk-pkgs-kv-warnings"
echo 'Generating SDK profiles evaluation list'
ROOT=/ "${PKG_AUTO_IMPL_DIR}/print_profile_tree.sh" -ni -nh >"${reports_dir}/sdk-profiles" 2>"${reports_dir}/sdk-profiles-warnings"
echo 'Generating SDK package source information'
package_sources_sdk >"${reports_dir}/sdk-package-repos" 2>"${reports_dir}/sdk-package-repos-warnings"

for arch; do
    echo "Generating ${arch} board packages listing"
    versions_board "${arch}" >"${reports_dir}/${arch}-board-pkgs" 2>"${reports_dir}/${arch}-board-pkgs-warnings"
    echo "Generating ${arch} board packages listing with key-values (USE, PYTHON_TARGETS, CPU_FLAGS_X86, etc)"
    versions_board_with_key_values "${arch}" >"${reports_dir}/${arch}-board-pkgs-kv" 2>"${reports_dir}/${arch}-board-pkgs-kv-warnings"
    echo "Generating ${arch} board packages bdeps listing"
    board_bdeps "${arch}" >"${reports_dir}/${arch}-board-bdeps" 2>"${reports_dir}/${arch}-board-bdeps-warnings"
    echo "Generating ${arch} board profiles evaluation list"
    ROOT="/build/${arch}-usr" "${PKG_AUTO_IMPL_DIR}/print_profile_tree.sh" -ni -nh >"${reports_dir}/${arch}-board-profiles" 2>"${reports_dir}/${arch}-board-profiles-warnings"
    echo "Generating ${arch} board package source information"
    package_sources_board "${arch}" >"${reports_dir}/${arch}-board-package-repos" 2>"${reports_dir}/${arch}-board-package-repos-warnings"
done

echo "Cleaning empty warning files"
clean_empty_warning_files "${reports_dir}"
