#!/bin/bash

# set -x
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/impl/util.sh"
source "${PKG_AUTO_IMPL_DIR}/md5_cache_lib.sh"
source "${PKG_AUTO_IMPL_DIR}/lcs.sh"
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

declare -gri PCF_EAPI_IDX=0 PCF_KEYWORDS_IDX=1 PCF_IUSE_IDX=2 PCF_BDEPEND_IDX=3 PCF_DEPEND_IDX=4 PCF_IDEPEND_IDX=5 PCF_PDEPEND_IDX=6 PCF_RDEPEND_IDX=7 PCF_LICENSE_IDX=8 PCF_ECLASSES_IDX=9

# TODO: move it to md5_cache_lib?
function parse_cache_file() {
    local path=${1}; shift
    local -i arch_args=$(( ${#} - 1 ))
    local -a arches=( ${@:1:${arch_args}} ); shift ${arch_args}
    local -n out_var_name_ref=${1}; shift

    local cache_name
    gen_varname cache_name

    declare -g -a "${cache_name}=( '0' 'EMPTY_ARRAY' 'EMPTY_ARRAY' 'EMPTY_GROUP' 'EMPTY_GROUP' 'EMPTY_GROUP' 'EMPTY_GROUP' 'EMPTY_GROUP' 'EMPTY_GROUP' 'EMPTY_ARRAY' )"

    # shellcheck disable=SC2034 # shellcheck does not grok references
    local -n cache=${cache_name}

    local -n pkg_eapi=cache[${PCF_EAPI_IDX}]
    local -n pkg_keywords=cache[${PCF_KEYWORDS_IDX}]
    local -n pkg_iuse=cache[${PCF_IUSE_IDX}]
    local -n pkg_bdepend_group_name=cache[${PCF_BDEPEND_IDX}]
    local -n pkg_depend_group_name=cache[${PCF_DEPEND_IDX}]
    local -n pkg_idepend_group_name=cache[${PCF_IDEPEND_IDX}]
    local -n pkg_pdepend_group_name=cache[${PCF_PDEPEND_IDX}]
    local -n pkg_rdepend_group_name=cache[${PCF_RDEPEND_IDX}]
    local -n pkg_license_group_name=cache[${PCF_LICENSE_IDX}]
    local -n pkg_eclasses=cache[${PCF_ECLASSES_IDX}]

    local l
    while read -r l; do
        case ${l} in
            EAPI=*)
                pkg_eapi=${l#*=}
                ;;
            KEYWORDS=*)
                parse_keywords "${l#*=}" pkg_keywords "${arches[@]}"
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

    out_var_name_ref=${cache_name}
}

function diff_eapi() {
    local -n old_ref=${1}; shift
    local -n new_ref=${1}; shift

    local old_eapi=${old_ref[${PCF_EAPI_IDX}]}
    local new_eapi=${new_ref[${PCF_EAPI_IDX}]}

    if [[ ${old_eapi} != "${new_eapi}" ]]; then
        echo "EAPI changed from ${old_eapi@Q} to ${new_eapi@Q}"
    fi
}

function diff_iuse() {
    local -n old_ref=${1}; shift
    local -n new_ref=${1}; shift

    local old_iuses_var_name=${old_ref[${PCF_IUSE_IDX}]}
    local new_iuses_var_name=${new_ref[${PCF_IUSE_IDX}]}

    local -A old_map=() new_map=() removed same added

    local -n old_iuses=${old_iuses_var_name} new_iuses=${new_iuses_var_name}

    local -i idx=0
    local iuse_var_name name
    for iuse_var_name in "${old_iuses[@]}"; do
        # shellcheck disable=SC2178 # shellcheck does not grok references
        local -n iuse=${iuse_var_name}
        # shellcheck disable=SC2034 # shellcheck does not grok references
        name=${iuse[${IUSE_NAME_IDX}]}
        old_map["${name}"]=${idx}
        unset -n iuse
        idx=$((idx + 1))
    done

    idx=0
    for iuse_var_name in "${new_iuses[@]}"; do
        # shellcheck disable=SC2178 # shellcheck does not grok references
        local -n iuse=${iuse_var_name}
        name=${iuse[${IUSE_NAME_IDX}]}
        new_map["${name}"]=${idx}
        unset -n iuse
        idx=$((idx + 1))
    done

    sets_split old_map new_map removed added same

    local iuse
    for iuse in "${!removed[@]}"; do
        echo "removed IUSE flag ${iuse@Q}"
    done
    for iuse in "${!added[@]}"; do
        echo "added IUSE flag ${iuse@Q}"
    done
    local old_mode new_mode mode_str
    local -i old_idx new_idx
    for iuse in "${!same[@]}"; do
        old_idx=${old_map["${iuse}"]}
        new_idx=${new_map["${iuse}"]}
        local -n old_iuse=${old_iuses[${old_idx}]} new_iuse=${new_iuses[${new_idx}]}
        old_mode=${old_iuse[${IUSE_MODE_IDX}]}
        new_mode=${new_iuse[${IUSE_MODE_IDX}]}
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

    local old_kws_var_name=${old_ref[${PCF_KEYWORDS_IDX}]}
    local new_kws_var_name=${new_ref[${PCF_KEYWORDS_IDX}]}

    local -n old_kws=${old_kws_var_name}
    local -n new_kws=${new_kws_var_name}

    if [[ ${#old_kws[@]} -ne ${#new_kws[@]} ]]; then
        fail 'keywords number should always be the same'
    fi

    local index old_name new_name old_level new_level level_str
    for (( index=0; index < ${#old_kws[@]}; ++index )); do
        local -n old_kw=${old_kws["${index}"]}
        local -n new_kw=${new_kws["${index}"]}
        old_name=${old_kw[${KW_NAME_IDX}]}
        new_name=${new_kw[${KW_NAME_IDX}]}
        if [[ ${old_name} != "${new_name}" ]]; then
            fail 'keywords of the same name should always have the same index'
        fi
        old_level=${old_kw[${KW_LEVEL_IDX}]}
        new_level=${new_kw[${KW_LEVEL_IDX}]}
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

function flatten_group() {
    local -n group_ref=${1}; shift
    local flattened_items_var_name=${1}; shift

    local -n flattened_items_ref=${flattened_items_var_name}
    local -n group_items=${group_ref[${GROUP_ITEMS_IDX}]}

    case ${group_ref[${GROUP_TYPE_IDX}]} in
        "${GROUP_ALL_OF}")
            local name=${group_ref[${GROUP_USE_IDX}]}
            if [[ -n ${name} ]]; then
                case ${group_ref[${GROUP_ENABLED_IDX}]} in
                    "${GROUP_USE_ENABLED}")
                        :
                        ;;
                    "${GROUP_USE_DISABLED}")
                        name="!${name}"
                        ;;
                esac
                name+='?'
                flattened_items_ref+=( "i:${name}" )
            fi
            unset name
            ;;
        "${GROUP_ANY_OF}")
            flattened_items_ref+=( "i:||" )
            ;;
    esac
    flattened_items_ref+=( "o:(" )

    local item_var_name item_type
    for item_var_name in "${group_items[@]}"; do
        local -n item_ref=${item_var_name}
        item_type=${item_ref%:*}
        case ${item_type} in
            'e')
                # do not add empty items to the list
                :
                ;;
            'g')
                local subgroup_name=${item_ref#*:}
                flatten_group "${subgroup_name}" "${flattened_items_var_name}"
                unset subgroup_name
                ;;
            'l'|'p')
                flattened_items_ref+=( "${item_ref}" )
                ;;
            *)
                fail "item ${item_ref} is bad"
                ;;
        esac
        unset -n item_ref
    done
    flattened_items_ref+=( "c:)" )
}

function flattened_group_item_eq() {
    local i1=${1}; shift
    local i2=${1}; shift

    local t1=${i1%:*}
    local t2=${i2%:*}

    if [[ ${t1} != "${t2}" ]]; then
        return 1
    fi

    local v1=${i1#*:}
    local v2=${i2#*:}
    local rv=0
    case ${t1} in
        'l'|'i')
            [[ ${v1} = "${v2}" ]] || rv=1
            ;;
        'p')
            local -n p1=${v1} p2=${v2}
            local n1=${p1[${PDS_NAME_IDX}]} n2=${p2[${PDS_NAME_IDX}]}
            [[ ${n1} = "${n2}" ]] || rv=1
            unset n2 n1
            unset -n p2 p1
            ;;
        'o'|'c')
            # parens are the same everywhere
            :
            ;;
        *)
            fail "item ${i1} or ${i2} is bad"
            ;;
    esac
    return ${rv}
}

function flattened_group_item_prep() {
    local item1=${1}; shift
    local item2=${1}; shift
    local idx1=${1}; shift
    local idx2=${1}; shift
    local -n ref=${1}; shift

    local n
    gen_varname n

    declare -g -a "${n}=( ${item1@Q} ${item2@Q} ${idx1@Q} ${idx2@Q} )"

    ref=${n}
}

function flattened_group_item_kill() {
    unset "${@}"
}

function ur_mode_description() {
    local mode=${1}; shift
    local -n str_ref=${1}; shift

    case ${mode} in
        '+')
            str_ref='enabled'
            ;;
        '=')
            str_ref='strict'
            ;;
        '!=')
            str_ref='reversed strict'
            ;;
        '?')
            str_ref='enabled if enabled'
            ;;
        '!?')
            str_ref='disabled if disabled'
            ;;
        '-')
            str_ref='disabled'
            ;;
    esac
}

function ur_pretend_description() {
    local pretend=${1}; shift
    local -n str_ref=${1}; shift

    case ${pretend} in
        '')
            str_ref='must exist, no pretending if missing'
            ;;
        '+')
            str_ref='will pretend as enabled if missing'
            ;;
        '-')
            str_ref='will pretend as disabled if missing'
            ;;
    esac
}

function pds_diff() {
    local -n old_pds=${1}; shift
    local -n new_pds=${1}; shift

    local name=${new_pds[${PDS_NAME_IDX}]}

    local old_blocks=${old_pds[${PDS_BLOCKS_IDX}]} new_blocks=${new_pds[${PDS_BLOCKS_IDX}]}
    if [[ ${old_blocks} -ne ${new_blocks} ]]; then
        local block
        case ${new_blocks} in
            ${PDS_NO_BLOCK})
                block='no'
                ;;
            ${PDS_WEAK_BLOCK})
                block='weak'
                ;;
            ${PDS_STRONG_BLOCK})
                block='strong'
                ;;
        esac
        echo "changed to ${block} block for ${name@Q}"
        unset block
    fi

    local old_op=${old_pds[${PDS_OP_IDX}]} old_ver=${old_pds[${PDS_VER_IDX}]} new_op=${new_pds[${PDS_OP_IDX}]} new_ver=${new_pds[${PDS_VER_IDX}]}
    if [[ ${old_op} != "${new_op}" || ${old_ver} != ${new_ver} ]]; then
        if [[ -z ${new_op} && -z ${new_ver} ]]; then
            echo "dropped version constraint on ${name}"
        elif [[ -z ${old_op} && -z ${old_ver} ]]; then
            echo "added version constraint ${new_op}${new_ver} on ${name}"
        else
            echo "changed version constraint on ${name} from ${old_op}${old_ver} to ${new_op}${new_ver}"
        fi
    fi

    local old_slot=${old_pds[${PDS_SLOT_IDX}]} new_slot=${new_pds[${PDS_SLOT_IDX}]}
    if [[ ${old_slot} != "${new_slot}" ]]; then
        if [[ -z ${new_slot} ]]; then
            echo "dropped slot constraint on ${name}"
        elif [[ -z ${old_slot} ]]; then
            echo "added slot constraint ${new_slot} on ${name}"
        else
            echo "changed slot constraint on ${name} from ${old_slot} to ${new_slot}"
        fi
    fi

    local -n old_urs=${old_pds[${PDS_UR_IDX}]} new_urs=${new_pds[${PDS_UR_IDX}]}
    local -A old_name_index=() new_name_index=()

    local ur_name use_name
    local -i idx=0
    for ur_name in "${old_urs[@]}"; do
        local -n ur=${ur_name}
        use_name=${ur[${UR_NAME_IDX}]}
        old_name_index["${use_name}"]=${idx}
        idx=$((idx + 1))
        unset -n ur
    done

    idx=0
    for ur_name in "${new_urs[@]}"; do
        local -n ur=${ur_name}
        use_name=${ur[${UR_NAME_IDX}]}
        new_name_index["${use_name}"]=${idx}
        idx=$((idx + 1))
        unset -n ur
    done

    local -A only_old_urs=() only_new_urs=() common_urs=()
    sets_split old_name_index new_name_index only_old_urs only_new_urs common_urs
    for use_name in "${!only_old_urs[@]}"; do
        echo "dropped ${use_name} use requirement on ${name}"
    done
    local pd_mode_str pd_pretend_str
    for use_name in "${!only_new_urs[@]}"; do
        idx=${new_name_index["${use_name}"]}
        local -n ur=${new_urs[${idx}]}
        ur_mode_description "${ur[${UR_MODE_IDX}]}" pd_mode_str
        ur_pretend_description "${ur[${UR_PRETEND_IDX}]}" pd_pretend_str
        echo "added ${use_name} use ${pd_mode_str} requirement on ${name} (${pd_pretend_str})"
    done

    local -i old_idx new_idx
    local old_mode new_mode old_pretend new_pretend pd_old_mode_str pd_new_mode_str pd_old_pretend_str pd_new_pretend_str
    for use_name in "${!common_urs[@]}"; do
        old_idx=${old_name_index["${use_name}"]}
        new_idx=${new_name_index["${use_name}"]}

        local -n old_ur=${old_urs[${old_idx}]} new_ur=${new_urs[${new_idx}]}
        old_mode=${old_ur[${UR_MODE_IDX}]}
        new_mode=${new_ur[${UR_MODE_IDX}]}
        if [[ ${old_mode} != ${new_mode} ]]; then
            ur_mode_description "${old_mode}" pd_old_mode_str
            ur_mode_description "${new_mode}" pd_new_mode_str
            echo "mode of use requirement on ${use_name} changed from ${pd_old_mode_str} to ${pd_new_mode_str} for ${name}"
        fi

        old_pretend=${old_ur[${UR_PRETEND_IDX}]}
        new_pretend=${new_ur[${UR_PRETEND_IDX}]}
        if [[ ${old_pretend} != "${new_pretend}" ]]; then
            ur_pretend_description "${old_pretend}" pd_old_pretend_str
            ur_pretend_description "${new_pretend}" pd_new_pretend_str
            echo "pretend mode of use requirement on ${use_name} changed from ${pd_old_pretend_str@Q} to ${pd_new_pretend_str@Q} for ${name}"
        fi
        unset -n new_ur old_ur
    done
}

function diff_deps() {
    local -n old_ref=${1}; shift
    local -n new_ref=${1}; shift
    local deps_idx=${1}; shift

    local old_group_name=${old_ref[${deps_idx}]} new_group_name=${new_ref[${deps_idx}]}
    local -a dd_old_flattened_list=() dd_new_flattened_list=()
    flatten_group "${old_group_name}" dd_old_flattened_list
    flatten_group "${new_group_name}" dd_new_flattened_list

    local dd_lcs=''
    local -a dd_common_items=()

    lcs_setup flattened_group_item dd_lcs
    lcs_run "${dd_lcs}" dd_old_flattened_list dd_new_flattened_list dd_common_items

    local -i last_idx1=0 last_idx2=0 idx1 idx2
    local ci_name check_todo=
    for ci_name in "${dd_common_items[@]}"; do
        local -n ci=${ci_name}
        idx1=${ci[2]}
        idx2=${ci[3]}
        while [[ ${last_idx1} -lt ${idx1} ]]; do
            local item1=${dd_old_flattened_list["${last_idx1}"]}
            local t1=${item1%:*} v1=${item1#*:}
            case ${t1} in
                'l')
                    echo "dropped license ${v1@Q}"
                    ;;
                'p')
                    local p_str=''
                    pds_to_string "${v1}" p_str
                    echo "dropped a dependency ${p_str@Q}"
                    ;;
                'o'|'c'|'i')
                    if [[ -z ${check_todo} ]]; then
                        echo "TODO: check the diff in ${deps_idx@Q}"
                        check_todo=x
                    fi
                    ;;
                *)
                    fail "item ${item1} is bad"
                    ;;
            esac
            unset v1 t1 item1
            last_idx1=$((last_idx1 + 1))
        done
        while [[ ${last_idx2} -lt ${idx2} ]]; do
            local item2=${dd_new_flattened_list["${last_idx2}"]}
            local t2=${item2%:*} v2=${item2#*:}
            case ${t2} in
                'l')
                    echo "added license ${v2@Q}"
                    ;;
                'p')
                    local p_str=''
                    pds_to_string "${v2}" p_str
                    echo "added a dependency ${p_str@Q}"
                    ;;
                'o'|'c'|'i')
                    if [[ -z ${check_todo} ]]; then
                        echo "TODO: check the diff in ${deps_idx@Q}"
                        check_todo=x
                    fi
                    ;;
                *)
                    fail "item ${item2} is bad"
                    ;;
            esac
            unset v2 t2 item2
            last_idx2=$((last_idx2 + 1))
        done

        local item1=${dd_old_flattened_list["${idx1}"]} item2=${dd_new_flattened_list["${idx2}"]}
        local t1=${item1%:*} v1=${item1#*:} t2=${item2%:*} v2=${item2#*:}

        case ${t1} in
            'o'|'c'|'l'|'i')
                # not interesting
                :
                ;;
            'p')
                pds_diff "${item1#*:}" "${item2#*:}"
                ;;
            *)
                fail "item ${item1} or ${item2} is bad"
                ;;
        esac

        unset v2 t2 item2
        unset v1 t1 item1
        unset -n ci
        last_idx1=$((last_idx1 + 1))
        last_idx2=$((last_idx2 + 1))
    done

    idx1=${#dd_old_flattened_list[@]}
    idx2=${#dd_new_flattened_list[@]}
    while [[ ${last_idx1} -lt ${idx1} ]]; do
        local item1=${dd_old_flattened_list["${last_idx1}"]}
        local t1=${item1%:*} v1=${item1#*:}
        case ${t1} in
            'l')
                echo "dropped license ${v1@Q}"
                ;;
            'p')
                local p_str=''
                pds_to_string "${v1}" p_str
                echo "dropped a dependency ${p_str@Q}"
                ;;
            'o'|'c'|'i')
                if [[ -z ${check_todo} ]]; then
                    echo "TODO: check the diff in ${deps_idx@Q}"
                    check_todo=x
                fi
                ;;
            *)
                fail "item ${item1} is bad"
                ;;
        esac
        unset v1 t1 item1
        last_idx1=$((last_idx1 + 1))
    done
    while [[ ${last_idx2} -lt ${idx2} ]]; do
        local item2=${dd_new_flattened_list["${last_idx2}"]}
        local t2=${item2%:*} v2=${item2#*:}
        case ${t2} in
            'l')
                echo "added license ${v2@Q}"
                ;;
            'p')
                local p_str=''
                pds_to_string "${v2}" p_str
                echo "added a dependency ${p_str@Q}"
                ;;
            'o'|'c'|'i')
                if [[ -z ${check_todo} ]]; then
                    echo "TODO: check the diff in ${deps_idx@Q}"
                    check_todo=x
                fi
                ;;
            *)
                fail "item ${item2} is bad"
                ;;
        esac
        unset v2 t2 item2
        last_idx2=$((last_idx2 + 1))
    done
}

function diff_cache_data() {
    local old_var_name=${1}; shift
    local new_var_name=${1}; shift

    diff_eapi "${old_var_name}" "${new_var_name}"
    diff_keywords "${old_var_name}" "${new_var_name}"
    diff_iuse "${old_var_name}" "${new_var_name}"

    local -i idx
    for idx in ${PCF_BDEPEND_IDX} ${PCF_DEPEND_IDX} ${PCF_IDEPEND_IDX} ${PCF_PDEPEND_IDX} ${PCF_RDEPEND_IDX} ${PCF_LICENSE_IDX}; do
        diff_deps "${old_var_name}" "${new_var_name}" ${idx}
    done
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

    parse_cache_file "${old_cache_entry}" "${arches[@]}" old_cache_name
    parse_cache_file "${new_cache_entry}" "${arches[@]}" new_cache_name

    for prefix in old new; do
        declare -n cache_name=${prefix}_cache_name
        declare -n version=${prefix}_version
        declare -n repo=${prefix}_repo

        echo "${pkg}-${version}::${repo}"

        declare -n cache=${cache_name}

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

        unset -n pkg_eclasses pkg_iuse pkg_keywords cache repo version cache_name
    done

    diff_cache_data "${old_cache_name}" "${new_cache_name}"
done
