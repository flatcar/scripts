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
    # shellcheck disable=SC2034 # shellcheck does not grok references
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
    # shellcheck disable=SC2034 # shellcheck does not grok references
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

function diff_eapi() {
    local -n old_ref=${1}; shift
    local -n new_ref=${1}; shift

    local old_eapi=${old_ref['eapi']}
    local new_eapi=${new_ref['eapi']}

    if [[ ${old_eapi} != "${new_eapi}" ]]; then
        echo "EAPI changed from ${old_eapi@Q} to ${new_eapi@Q}"
    fi
}

function diff_iuse() {
    local -n old_ref=${1}; shift
    local -n new_ref=${1}; shift

    local old_iuse_var_name=${old_ref['iuse']}
    local new_iuse_var_name=${new_ref['iuse']}

    local -A old_map=() new_map=() removed same added
    local iuse_var_name name

    local -n iuse_array=${old_iuse_var_name}
    for iuse_var_name in "${iuse_array[@]}"; do
        # shellcheck disable=SC2178 # shellcheck does not grok references
        local -n iuse=${iuse_var_name}
        # shellcheck disable=SC2034 # shellcheck does not grok references
        name=${iuse['n']}
        # shellcheck disable=SC2034 # shellcheck does not grok references
        old_set["${name}"]=${iuse['m']}
        unset -n iuse
    done
    unset -n iuse_array

    local -n iuse_array=${new_iuse_var_name}
    for iuse_var_name in "${iuse_array[@]}"; do
        # shellcheck disable=SC2178 # shellcheck does not grok references
        local -n iuse=${iuse_var_name}
        name=${iuse['n']}
        # shellcheck disable=SC2034 # shellcheck does not grok references
        new_set["${name}"]=${iuse['m']}
        unset -n iuse
    done
    unset -n iuse_array

    sets_split old_map new_map removed same added

    local iuse
    for iuse in "${!removed[@]}"; do
        echo "removed IUSE flag ${iuse@Q}"
    done
    for iuse in "${!added[@]}"; do
        echo "added IUSE flag ${iuse@Q}"
    done
    local old_mode new_mode mode_str
    for iuse in "${!same[@]}"; do
        old_mode=${old_map["${iuse}"]}
        new_mode=${new_map["${iuse}"]}
        if [[ ${old_mode} -ne ${new_mode} ]]; then
            case ${new_mode} in
                "${IUSE_DISABLED}")
                    mode_str=disabled
                    ;;
                "${IUSE_ENABLED}")
                    mode_str=enabled
                    ;;
            esac
            echo "IUSE flag ${iuse@Q} became ${mode_str} by default"
        fi
    done
}

function diff_keywords() {
    local -n old_ref=${1}; shift
    local -n new_ref=${1}; shift

    local old_kws_var_name=${old_ref['keywords']}
    local new_kws_var_name=${new_ref['keywords']}

    local -n old_kws=${old_kws_var_name}
    local -n new_kws=${new_kws_var_name}

    if [[ ${#old_kws[@]} -ne ${#new_kws[@]} ]]; then
        fail 'keywords number should always be the same'
    fi

    local index old_name new_name old_level new_level level_str
    for (( index=0; index < ${#old_kws[@]}; ++index )); do
        local -n old_kw=${old_kws["${index}"]}
        local -n new_kw=${new_kws["${index}"]}
        old_name=${old_kw['n']}
        new_name=${new_kw['n']}
        if [[ ${old_name} != "${new_name}" ]]; then
            fail 'keywords of the same name should always have the same index'
        fi
        old_level=${old_kw['l']}
        new_level=${new_kw['l']}
        if [[ ${old_level} -ne ${new_level} ]]; then
            case ${new_level} in
                "${KW_STABLE}")
                    level_str='stable'
                    ;;
                "${KW_UNSTABLE}")
                    level_str='unstable'
                    ;;
                "${KW_BROKEN}")
                    level_str='broken'
                    ;;
                "${KW_UNKNOWN}")
                    level_str='unknown'
                    ;;
            esac
            echo "package became ${level_str} for ${new_name@Q}"
        fi
        unset -n new_kw old_kw
    done
}

function diff_deps() {
    :
}

function diff_cache_data() {
    local -n old_var_name=${1}; shift
    local -n new_var_name=${1}; shift

    diff_eapi "${old_var_name}" "${new_var_name}"
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

        echo "ECLASSES: ${pkg_used_eclasses[*]}"

        top_group_print 'LICENSE' "${pkg_license_group_name}"

        unset -n pkg_used_eclasses pkg_iuse pkg_keywords data repo version
    done

    # diff_cache_data old_data new_data

done
