#!/bin/bash

# set -x
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/impl/util.sh"
source "${PKG_AUTO_IMPL_DIR}/md5_cache_lib.sh"
source "${PKG_AUTO_IMPL_DIR}/gentoo_ver.sh"
source "${PKG_AUTO_IMPL_DIR}/md5_cache_diff_lib.sh"

#__UTIL_SH_DEBUG_COUNTERS[336]=x
#__UTIL_SH_DEBUG_COUNTERS[337]=x
#__UTIL_SH_DEBUG_COUNTERS[657]=x
#__UTIL_SH_DEBUG_COUNTERS[463]=x

function load_pkgs() {
    local reports_dir=${1}; shift
    local prefix=${1}; shift
    local pkgs_name=${1}; shift
    local repos_name=${1}; shift

    declare -a amd64_board_pkgs=() arm64_board_pkgs=() sdk_pkgs=()
    declare -a amd64_board_pkg_repos=() arm64_board_pkg_repos=() sdk_pkg_repos=()

    declare -A -g "${pkgs_name}=()" "${repos_name}=()"

    mapfile -t amd64_board_pkgs < <(cat "${reports_dir}/amd64-board-pkgs")
    mapfile -t arm64_board_pkgs < <(cat "${reports_dir}/arm64-board-pkgs")
    mapfile -t sdk_pkgs < <(cat "${reports_dir}/sdk-pkgs")
    mapfile -t amd64_board_pkg_repos < <(cat "${reports_dir}/amd64-board-package-repos")
    mapfile -t arm64_board_pkg_repos < <(cat "${reports_dir}/arm64-board-package-repos")
    mapfile -t sdk_pkg_repos < <(cat "${reports_dir}/sdk-package-repos")

    local -n pkgs=${pkgs_name}
    local -n pkg_repos=${repos_name}

    local l pkg version existing_version g_result
    for l in "${amd64_board_pkgs[@]}" "${arm64_board_pkgs[@]}" "${sdk_pkgs[@]}" ; do
        pkg=${l% *}
        version=${l#* }
        version=${version%:*}
        existing_version=${pkgs["${pkg}"]:-}
        if [[ -n ${existing_version} ]]; then
            g_result=''
            gentoo_ver_cmp_out "${version}" "${existing_version}" g_result
            if [[ ${g_result} -eq "${GV_GT}" ]]; then
                pkgs["${pkg}"]=${version}
            fi
        else
            pkgs["${pkg}"]=${version}
        fi
    done

    local repo existing_repo
    for l in "${amd64_board_pkg_repos[@]}" "${arm64_board_pkg_repos[@]}" "${sdk_pkg_repos[@]}"; do
        pkg=${l% *}
        repo=${l#* }
        existing_repo=${pkg_repos["${pkg}"]:-}
        if [[ -n ${existing_repo} ]]; then
            if [[ "${existing_repo}" != "${repo}" ]]; then
                fail "inconsistent repos for package ${pkg@Q}: ${existing_repo@Q} vs ${repo@Q}"
            fi
        else
            pkg_repos["${pkg}"]=${repo}
        fi
    done
}

function top_group_print() {
    local label=${1}; shift
    local group_name=${1}; shift

    #group_declare some_group_copy_test
    #group_copy some_group_copy_test "${group_name}"
    #group_name=some_group_copy_test

    local top_group_str=''
    group_to_string "${group_name}" top_group_str
    top_group_str=${top_group_str#'('}
    top_group_str=${top_group_str##' '}
    top_group_str=${top_group_str%')'}
    top_group_str=${top_group_str%%' '}
    echo "${label}: ${top_group_str}"
}

function main() {

local p1_reports_dir=${1}; shift

local p1_old_reports_dir=${p1_reports_dir}/old
local p1_new_reports_dir=${p1_reports_dir}/new

local -A p1_picked_pkg_set=()

local p1_pkg
for p1_pkg; do
    p1_picked_pkg_set["${p1_pkg}"]=x
done

load_pkgs "${p1_old_reports_dir}" old p1_old_pkgs p1_old_pkg_repos
load_pkgs "${p1_new_reports_dir}" new p1_new_pkgs p1_new_pkg_repos

local p1_old_version p1_new_version p1_old_repo p1_new_repo
local p1_old_cache_entry p1_new_cache_entry
local -a p1_arches=(amd64 arm64)
local p1_prefix

local p1_pkg_eapi
local p1_pkg_bdepend_group_name
local p1_pkg_depend_group_name
local p1_pkg_idepend_group_name
local p1_pkg_pdepend_group_name
local p1_pkg_rdepend_group_name
local p1_pkg_license_group_name

local p1_kws_str p1_kw p1_kw_str p1_use_str p1_u p1_iuse_str p1_l p1_indent p1_txt

for p1_pkg in "${!p1_picked_pkg_set[@]}"; do

    p1_old_version=${p1_old_pkgs["${p1_pkg}"]:-}
    p1_new_version=${p1_new_pkgs["${p1_pkg}"]:-}
    p1_old_repo=${p1_old_pkg_repos["${p1_pkg}"]:-}
    p1_new_repo=${p1_new_pkg_repos["${p1_pkg}"]:-}

    if [[ -z ${p1_old_version} ]]; then
        fail "No package ${p1_pkg@Q} in the old set"
    fi

    if [[ -z ${p1_new_version} ]]; then
        fail "No package ${p1_pkg@Q} in the new set"
    fi

    if [[ -z ${p1_old_repo} ]]; then
        fail "unknown repo for ${p1_pkg@Q} in old set"
    fi

    if [[ -z ${p1_new_repo} ]]; then
        fail "unknown repo for ${p1_pkg@Q} in new set"
    fi

    p1_old_cache_entry="${p1_old_reports_dir}/${p1_old_repo}-cache/${p1_pkg}-${p1_old_version}"
    p1_new_cache_entry="${p1_new_reports_dir}/${p1_new_repo}-cache/${p1_pkg}-${p1_new_version}"

    cache_file_declare p1_old_cache_file
    cache_file_declare p1_new_cache_file

    parse_cache_file p1_old_cache_file "${p1_old_cache_entry}" "${p1_arches[@]}"
    parse_cache_file p1_new_cache_file "${p1_new_cache_entry}" "${p1_arches[@]}"

    for p1_prefix in old new; do
        local -n p1_cache=p1_${p1_prefix}_cache_file
        local -n p1_version=p1_${p1_prefix}_version
        local -n p1_repo=p1_${p1_prefix}_repo

        echo "${p1_pkg}-${p1_version}::${p1_repo}"

        p1_pkg_eapi=${p1_cache[PCF_EAPI_IDX]}
        local -n p1_pkg_keywords=${p1_cache[PCF_KEYWORDS_IDX]}
        local -n p1_pkg_iuse=${p1_cache[PCF_IUSE_IDX]}
        p1_pkg_bdepend_group_name=${p1_cache[PCF_BDEPEND_IDX]}
        p1_pkg_depend_group_name=${p1_cache[PCF_DEPEND_IDX]}
        p1_pkg_idepend_group_name=${p1_cache[PCF_IDEPEND_IDX]}
        p1_pkg_pdepend_group_name=${p1_cache[PCF_PDEPEND_IDX]}
        p1_pkg_rdepend_group_name=${p1_cache[PCF_RDEPEND_IDX]}
        p1_pkg_license_group_name=${p1_cache[PCF_LICENSE_IDX]}
        local -n p1_pkg_eclasses=${p1_cache[PCF_ECLASSES_IDX]}

        echo "EAPI: ${p1_pkg_eapi}"
        p1_kws_str=''
        if [[ ${#p1_pkg_keywords[@]} -gt 0 ]]; then
            for p1_kw in "${p1_pkg_keywords[@]}"; do
                p1_kw_str=''
                kw_to_string "${p1_kw}" p1_kw_str
                if [[ -n ${p1_kw_str} ]]; then
                    p1_kws_str+=${p1_kw_str}' '
                fi
            done
            # remove trailing space
            p1_kws_str=${p1_kws_str:0:$(( ${#p1_kws_str} - 1 ))}
        fi
        echo "KEYWORDS: ${p1_kws_str}"

        p1_use_str=''
        if [[ ${#p1_pkg_iuse[@]} -gt 0 ]]; then
            for p1_u in "${p1_pkg_iuse[@]}"; do
                p1_iuse_str=''
                iuse_to_string "${p1_u}" p1_iuse_str
                p1_use_str+=${p1_iuse_str}' '
            done
            # remove trailing space
            p1_use_str=${p1_use_str:0:$(( ${#p1_use_str} - 1 ))}
        fi

        echo "IUSE: ${p1_use_str}"

        top_group_print 'BDEPEND' "${p1_pkg_bdepend_group_name}"
        top_group_print 'DEPEND' "${p1_pkg_depend_group_name}"
        top_group_print 'IDEPEND' "${p1_pkg_idepend_group_name}"
        top_group_print 'PDEPEND' "${p1_pkg_pdepend_group_name}"
        top_group_print 'RDEPEND' "${p1_pkg_rdepend_group_name}"

        echo "ECLASSES: ${p1_pkg_eclasses[*]}"

        top_group_print 'LICENSE' "${p1_pkg_license_group_name}"

        unset -n p1_pkg_eclasses
        unset -n p1_pkg_iuse
        unset -n p1_pkg_keywords
        unset -n p1_repo
        unset -n p1_version
        unset -n p1_cache
    done

    diff_report_declare p1_pkg_diff_report
    diff_cache_data p1_old_cache_file p1_new_cache_file p1_pkg_diff_report
    cache_file_unset p1_old_cache_file
    cache_file_unset p1_new_cache_file
    local -n p1_lines=${p1_pkg_diff_report[DR_LINES_IDX]}
    for p1_l in "${p1_lines[@]}"; do
        p1_indent=${p1_l%%:*}
        p1_txt=${p1_l#*:}
        if [[ ${p1_indent} -gt 0 ]]; then
            printf -- '  %.0s' $(seq 1 ${p1_indent})
        fi
        printf -- '- %s\n' "${p1_txt}"
    done
    unset -n p1_lines
    diff_report_unset p1_pkg_diff_report
done

unset p1_old_pkgs p1_new_pkgs p1_old_pkg_repos p1_new_pkg_repos

}

main "${@}"
#echo $?
declare -p
