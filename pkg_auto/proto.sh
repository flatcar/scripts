#!/bin/bash

# set -x
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/impl/util.sh"
source "${PKG_AUTO_IMPL_DIR}/md5_cache_lib.sh"
source "${PKG_AUTO_IMPL_DIR}/gentoo_ver.sh"

arch_reports_dir=${1}; shift

declare -A picked_pkg_set=()

for pkg; do
    picked_pkg_set["${pkg}"]=x
done

declare -a board_pkgs=() sdk_pkgs=()
declare -A pkgs=() pkg_repos=()

mapfile -t board_pkgs < <(cat "${arch_reports_dir}/board-pkgs")
mapfile -t sdk_pkgs < <(cat "${arch_reports_dir}/sdk-pkgs")
mapfile -t board_pkg_repos < <(cat "${arch_reports_dir}/board-package-repos")
mapfile -t sdk_pkg_repos < <(cat "${arch_reports_dir}/sdk-package-repos")

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

for pkg in "${!pkgs[@]}"; do

    if [[ ${#picked_pkg_set[@]} -gt 0 ]]; then
        mark=${picked_pkg_set["${pkg}"]:-}
        if [[ -z ${mark} ]]; then
            unset mark
            continue
        fi
        unset mark
    fi

    version=${pkgs["${pkg}"]}
    repo=${pkg_repos["${pkg}"]:-}
    if [[ -z ${repo} ]]; then
        fail "unknown repo for ${pkg@Q}"
    fi

    echo "${pkg}-${version}::${repo}"

    cache_entry="${arch_reports_dir}/${repo}-cache/${pkg}-${version}"
    pkg_eapi=0
    pkg_keywords=()
    pkg_iuse=()
    pkg_bdepend_group_name=EMPTY_GROUP
    pkg_depend_group_name=EMPTY_GROUP
    pkg_idepend_group_name=EMPTY_GROUP
    pkg_pdepend_group_name=EMPTY_GROUP
    pkg_rdepend_group_name=EMPTY_GROUP
    pkg_license_group_name=EMPTY_GROUP
    pkg_used_eclasses=()
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
                parse_eclasses "${l#*=}" pkg_used_eclasses
                ;;
        esac
    done <"${cache_entry}"

    echo "EAPI: ${pkg_eapi}"
    echo "KEYWORDS: ${pkg_keywords[*]}"
    use_str=''
    if [[ ${#pkg_iuse[@]} -gt 0 ]]; then
        for u in "${pkg_iuse[@]}"; do
            declare -n i=${u}
            case ${i[m]} in
                ${IUSE_ENABLED})
                    use_str+='+'
                    ;;
            esac
            use_str+=${i[n]}' '
            unset -n i
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

done
