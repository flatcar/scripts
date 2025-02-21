#!/bin/bash

# set -x
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/impl/util.sh"
source "${PKG_AUTO_IMPL_DIR}/md5_cache_lib.sh"
source "${PKG_AUTO_IMPL_DIR}/gentoo_ver.sh"

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

function parse_cache_file() {
    local path=${1}; shift
    local var_name=${1}; shift

    declare -g -A "${var_name}=( [eapi]=0 [keywords]=EMPTY_ARRAY [iuse]=EMPTY_ARRAY [bdepend]=EMPTY_GROUP [depend]=EMPTY_GROUP [idepend]=EMPTY_GROUP [pdepend]=EMPTY_GROUP [rdepend]=EMPTY_GROUP [license]=EMPTY_GROUP [eclasses]=EMPTY_ARRAY )"
    local -n cache=${var_name}

    local -n pkg_eapi=cache['eapi']
    local -n pkg_keywords=cache['keywords']
    local -n pkg_iuse=cache['iuse']
    local -n pkg_bdepend_group_name=cache['bdepend']
    local -n pkg_depend_group_name=cache['depend']
    local -n pkg_idepend_group_name=cache['idepend']
    local -n pkg_pdepend_group_name=cache['pdepend']
    local -n pkg_rdepend_group_name=cache['rdepend']
    local -n pkg_license_group_name=cache['license']
    local -n pkg_eclasses=cache['eclasses']

    local l
    while read -r l; do
        case ${l} in
            EAPI=*)
                pkg_eapi=${l#*=}
                ;;
            KEYWORDS=*)
                parse_keywords "${l#*=}" pkg_keywords amd64 arm64
                ;;
            IUSE=*)
                parse_iuse "${l#*=}" pkg_iuse
                ;;
            BDEPEND=*)
                parse_dsf "${DSF_DEPEND}" "${l#*=}" pkg_bdepend_group_name
                ;;
            DEPEND=*)
                parse_dsf "${DSF_DEPEND}" "${l#*=}" pkg_depend_group_name
                ;;
            IDEPEND=*)
                parse_dsf "${DSF_DEPEND}" "${l#*=}" pkg_idepend_group_name
                ;;
            PDEPEND=*)
                parse_dsf "${DSF_DEPEND}" "${l#*=}" pkg_pdepend_group_name
                ;;
            RDEPEND=*)
                parse_dsf "${DSF_DEPEND}" "${l#*=}" pkg_rdepend_group_name
                ;;
            LICENSE=*)
                parse_dsf "${DSF_LICENSE}" "${l#*=}" pkg_license_group_name
                ;;
            _eclasses_=*)
                parse_eclasses "${l#*=}" pkg_eclasses
                ;;
        esac
    done <"${path}"
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

    parse_cache_file "${old_cache_entry}" old_data
    parse_cache_file "${new_cache_entry}" new_data

    for prefix in old new; do
        declare -n version=${prefix}_version
        declare -n repo=${prefix}_repo

        echo "${pkg}-${version}::${repo}"

        declare -n data=${prefix}_data
        pkg_eapi=${data['eapi']}
        declare -n pkg_keywords=${data['keywords']}
        declare -n pkg_iuse=${data['iuse']}
        pkg_bdepend_group_name=${data['bdepend']}
        pkg_depend_group_name=${data['depend']}
        pkg_idepend_group_name=${data['idepend']}
        pkg_pdepend_group_name=${data['pdepend']}
        pkg_rdepend_group_name=${data['rdepend']}
        declare -n pkg_used_eclasses=${data['eclasses']}
        pkg_license_group_name=${data['license']}

        echo "EAPI: ${pkg_eapi}"
        echo "KEYWORDS: ${pkg_keywords[*]}"
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

        echo "ECLASSES: ${pkg_used_eclasses[*]}"

        top_group_print 'LICENSE' "${pkg_license_group_name}"

        unset -n pkg_used_eclasses pkg_iuse pkg_keywords data repo version
    done
done
