#!/bin/bash

# set -x
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/impl/util.sh"
source "${PKG_AUTO_IMPL_DIR}/md5_cache_lib.sh"
source "${PKG_AUTO_IMPL_DIR}/lcs.sh"
source "${PKG_AUTO_IMPL_DIR}/gentoo_ver.sh"
source "${PKG_AUTO_IMPL_DIR}/md5_cache_diff_lib.sh"

arch_old_reports_dir=${1}; shift
arch_new_reports_dir=${1}; shift

declare -A picked_pkg_set=()

for pkg; do
    picked_pkg_set["${pkg}"]=x
done

function load_pkgs() {
    local arch_reports_dir=${1}; shift
    local prefix=${1}

    declare -a board_pkgs=() sdk_pkgs=()
    declare -a board_pkg_repos=() sdk_pkg_repos=()

    declare -A -g "${prefix}_pkgs=()" "${prefix}_pkg_repos=()"

    mapfile -t board_pkgs < <(cat "${arch_reports_dir}/board-pkgs")
    mapfile -t sdk_pkgs < <(cat "${arch_reports_dir}/sdk-pkgs")
    mapfile -t board_pkg_repos < <(cat "${arch_reports_dir}/board-package-repos")
    mapfile -t sdk_pkg_repos < <(cat "${arch_reports_dir}/sdk-package-repos")

    local -n pkgs=${prefix}_pkgs
    local -n pkg_repos=${prefix}_pkg_repos

    local l pkg version existing_version g_result
    for l in "${board_pkgs[@]}" "${sdk_pkgs[@]}" ; do
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
    for l in "${board_pkg_repos[@]}" "${sdk_pkg_repos[@]}"; do
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

    local top_group_str=''
    group_to_string "${group_name}" top_group_str
    top_group_str=${top_group_str#'('}
    top_group_str=${top_group_str##' '}
    top_group_str=${top_group_str%')'}
    top_group_str=${top_group_str%%' '}
    echo "${label}: ${top_group_str}"
}

load_pkgs "${arch_old_reports_dir}" old
load_pkgs "${arch_new_reports_dir}" new

for pkg in "${!picked_pkg_set[@]}"; do

    old_version=${old_pkgs["${pkg}"]:-}
    new_version=${new_pkgs["${pkg}"]:-}
    old_repo=${old_pkg_repos["${pkg}"]:-}
    new_repo=${new_pkg_repos["${pkg}"]:-}

    if [[ -z ${old_version} ]]; then
        fail "No package ${pkg@Q} in the old set"
    fi

    if [[ -z ${new_version} ]]; then
        fail "No package ${pkg@Q} in the new set"
    fi

    if [[ -z ${old_repo} ]]; then
        fail "unknown repo for ${pkg@Q} in old set"
    fi

    if [[ -z ${new_repo} ]]; then
        fail "unknown repo for ${pkg@Q} in new set"
    fi

    old_cache_entry="${arch_old_reports_dir}/${old_repo}-cache/${pkg}-${old_version}"
    new_cache_entry="${arch_new_reports_dir}/${new_repo}-cache/${pkg}-${new_version}"

    arches=(amd64 arm64)

    cache_file_declare old_cache_file
    cache_file_declare new_cache_file

    parse_cache_file old_cache_file "${old_cache_entry}" "${arches[@]}"
    parse_cache_file new_cache_file "${new_cache_entry}" "${arches[@]}"

    for prefix in old new; do
        declare -n cache=${prefix}_cache_file
        declare -n version=${prefix}_version
        declare -n repo=${prefix}_repo

        echo "${pkg}-${version}::${repo}"

        pkg_eapi=${cache[${PCF_EAPI_IDX}]}
        declare -n pkg_keywords=${cache[${PCF_KEYWORDS_IDX}]}
        declare -n pkg_iuse=${cache[${PCF_IUSE_IDX}]}
        pkg_bdepend_group_name=${cache[${PCF_BDEPEND_IDX}]}
        pkg_depend_group_name=${cache[${PCF_DEPEND_IDX}]}
        pkg_idepend_group_name=${cache[${PCF_IDEPEND_IDX}]}
        pkg_pdepend_group_name=${cache[${PCF_PDEPEND_IDX}]}
        pkg_rdepend_group_name=${cache[${PCF_RDEPEND_IDX}]}
        pkg_license_group_name=${cache[${PCF_LICENSE_IDX}]}
        declare -n pkg_eclasses=${cache[${PCF_ECLASSES_IDX}]}

        echo "EAPI: ${pkg_eapi}"
        kws_str=''
        if [[ ${#pkg_keywords[@]} -gt 0 ]]; then
            for kw in "${pkg_keywords[@]}"; do
                kw_str=''
                kw_to_string "${kw}" kw_str
                if [[ -n ${kw_str} ]]; then
                    kws_str+=${kw_str}' '
                fi
            done
            # remove trailing space
            kws_str=${kws_str:0:$(( ${#kws_str} - 1 ))}
        fi
        echo "KEYWORDS: ${kws_str}"
        use_str=''
        if [[ ${#pkg_iuse[@]} -gt 0 ]]; then
            for u in "${pkg_iuse[@]}"; do
                iuse_str=''
                iuse_to_string "${u}" iuse_str
                use_str+=${iuse_str}' '
            done
            # remove trailing space
            use_str=${use_str:0:$(( ${#use_str} - 1 ))}
        fi

        echo "IUSE: ${use_str}"

        top_group_print 'BDEPEND' "${pkg_bdepend_group_name}"
        top_group_print 'DEPEND' "${pkg_depend_group_name}"
        top_group_print 'IDEPEND' "${pkg_idepend_group_name}"
        top_group_print 'PDEPEND' "${pkg_pdepend_group_name}"
        top_group_print 'RDEPEND' "${pkg_rdepend_group_name}"

        echo "ECLASSES: ${pkg_eclasses[*]}"

        top_group_print 'LICENSE' "${pkg_license_group_name}"

        unset -n pkg_eclasses pkg_iuse pkg_keywords version repo cache
    done

    diff_report_declare pkg_diff_report
    diff_cache_data old_cache_file new_cache_file pkg_diff_report
    declare -n lines=${pkg_diff_report[${DR_LINES_IDX}]}
    for l in "${lines[@]}"; do
        indent=${l%%:*}
        txt=${l#*:}
        if [[ ${indent} -gt 0 ]]; then
            printf -- '  %.0s' $(seq 1 ${indent})
        fi
        printf -- '- %s\n' "${txt}"
    done
    unset -n lines
    diff_report_unset pkg_diff_report
done
