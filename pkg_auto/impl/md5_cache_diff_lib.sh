#!/bin/bash

if [[ -z ${__MD5_CACHE_DIFF_LIB_SH_INCLUDED__:-} ]]; then
__MD5_CACHE_DIFF_LIB_SH_INCLUDED__=x

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"
source "${PKG_AUTO_IMPL_DIR}/md5_cache_lib.sh"

declare -gri DR_INDENT_IDX=0 DR_LINES_IDX=1

function diff_report_declare() {
    local name=${1}; shift

    declare -g -a "${name}=( 0 EMPTY_ARRAY )"
}

function diff_report_unset() {
    local dr_var_name=${1}; shift
    local -n dr_ref=${dr_var_name}
    local lines_var_name=${dr_ref[${DR_LINES_IDX}]}

    if [[ ${lines_var_name} != EMPTY_ARRAY ]]; then
        unset "${lines_var_name}"
    fi
    unset -n dr_ref
    unset "${dr_var_name}"
}

function diff_report_append() {
    local -n dr_ref=${1}; shift
    local line=${1}; shift

    local dra_lines_name=${dr_ref[${DR_LINES_IDX}]}
    if [[ ${dra_lines_name} == EMPTY_ARRAY ]]; then
        gen_varname dra_lines_name
        declare -g -a "${dra_lines_name}=()"
        dr_ref[${DR_LINES_IDX}]=${dra_lines_name}
    fi

    local indent
    indent=${dr_ref[${DR_INDENT_IDX}]}

    local indent_line=${indent}:${line}

    local -n lines_ref=${dra_lines_name}
    lines_ref+=( "${indent_line}" )
}

function diff_report_append_indented() {
    local dr_var_name=${1}; shift
    local line=${1}; shift

    diff_report_indent "${dr_var_name}"
    diff_report_append "${dr_var_name}" "${line}"
    diff_report_dedent "${dr_var_name}"
}

function diff_report_indent() {
    local -n dr_ref=${1}; shift

    : $((dr_ref[${DR_INDENT_IDX}]++))
}

function diff_report_dedent() {
    local -n dr_ref=${1}; shift

    : $((dr_ref[${DR_INDENT_IDX}]--))
}

function diff_eapi() {
    local -n old_ref=${1}; shift
    local -n new_ref=${1}; shift
    local dr_var_name=${1}; shift

    local old_eapi=${old_ref[${PCF_EAPI_IDX}]}
    local new_eapi=${new_ref[${PCF_EAPI_IDX}]}

    if [[ ${old_eapi} != "${new_eapi}" ]]; then
        diff_report_append "${dr_var_name}" "EAPI changed from ${old_eapi@Q} to ${new_eapi@Q}"
    fi
}

function diff_iuse() {
    local -n old_ref=${1}; shift
    local -n new_ref=${1}; shift
    local dr_var_name=${1}; shift

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
        diff_report_append "${dr_var_name}" "removed IUSE flag ${iuse@Q}"
        diff_report_append_indented "${dr_var_name}" "TODO: describe removed IUSE flag"
    done
    for iuse in "${!added[@]}"; do
        diff_report_append "${dr_var_name}" "added IUSE flag ${iuse@Q}"
        diff_report_append_indented "${dr_var_name}" "TODO: describe added IUSE flag"
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
            diff_report_append "${dr_var_name}" "IUSE flag ${iuse@Q} became ${mode_str} by default"
        fi
    done
}

function diff_keywords() {
    local -n old_ref=${1}; shift
    local -n new_ref=${1}; shift
    local dr_var_name=${1}; shift

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
            diff_report_append "${dr_var_name}" "package became ${level_str} on ${new_name@Q}"
        fi
        unset -n new_kw old_kw
    done
}

function __mcdl_flatten_group() {
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
                __mcdl_flatten_group "${subgroup_name}" "${flattened_items_var_name}"
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

function __mcdl_flattened_group_item_eq() {
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

function __mcdl_ur_mode_description() {
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

function __mcdl_ur_pretend_description() {
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
    local dr_var_name=${1}; shift

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
        diff_report_append "${dr_var_name}" "changed to ${block} block for ${name@Q}"
        unset block
    fi

    local old_op=${old_pds[${PDS_OP_IDX}]} old_ver=${old_pds[${PDS_VER_IDX}]} new_op=${new_pds[${PDS_OP_IDX}]} new_ver=${new_pds[${PDS_VER_IDX}]}
    if [[ ${old_op} != "${new_op}" || ${old_ver} != ${new_ver} ]]; then
        if [[ -z ${new_op} && -z ${new_ver} ]]; then
            diff_report_append "${dr_var_name}" "dropped version constraint on ${name}"
        elif [[ -z ${old_op} && -z ${old_ver} ]]; then
            diff_report_append "${dr_var_name}" "added version constraint ${new_op}${new_ver} on ${name}"
        else
            diff_report_append "${dr_var_name}" "changed version constraint on ${name} from ${old_op}${old_ver} to ${new_op}${new_ver}"
        fi
    fi

    local old_slot=${old_pds[${PDS_SLOT_IDX}]} new_slot=${new_pds[${PDS_SLOT_IDX}]}
    if [[ ${old_slot} != "${new_slot}" ]]; then
        if [[ -z ${new_slot} ]]; then
            diff_report_append "${dr_var_name}" "dropped slot constraint on ${name}"
        elif [[ -z ${old_slot} ]]; then
            diff_report_append "${dr_var_name}" "added slot constraint ${new_slot} on ${name}"
        else
            diff_report_append "${dr_var_name}" "changed slot constraint on ${name} from ${old_slot} to ${new_slot}"
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
        diff_report_append "${dr_var_name}" "dropped ${use_name} use requirement on ${name}"
    done
    local pd_mode_str pd_pretend_str
    for use_name in "${!only_new_urs[@]}"; do
        idx=${new_name_index["${use_name}"]}
        local -n ur=${new_urs[${idx}]}
        __mcdl_ur_mode_description "${ur[${UR_MODE_IDX}]}" pd_mode_str
        __mcdl_ur_pretend_description "${ur[${UR_PRETEND_IDX}]}" pd_pretend_str
        diff_report_append "${dr_var_name}" "added ${use_name} use ${pd_mode_str} requirement on ${name} (${pd_pretend_str})"
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
            __mcdl_ur_mode_description "${old_mode}" pd_old_mode_str
            __mcdl_ur_mode_description "${new_mode}" pd_new_mode_str
            diff_report_append "${dr_var_name}" "mode of use requirement on ${use_name} changed from ${pd_old_mode_str} to ${pd_new_mode_str} for ${name}"
        fi

        old_pretend=${old_ur[${UR_PRETEND_IDX}]}
        new_pretend=${new_ur[${UR_PRETEND_IDX}]}
        if [[ ${old_pretend} != "${new_pretend}" ]]; then
            __mcdl_ur_pretend_description "${old_pretend}" pd_old_pretend_str
            __mcdl_ur_pretend_description "${new_pretend}" pd_new_pretend_str
            diff_report_append "${dr_var_name}" "pretend mode of use requirement on ${use_name} changed from ${pd_old_pretend_str@Q} to ${pd_new_pretend_str@Q} for ${name}"
        fi
        unset -n new_ur old_ur
    done
}

function diff_deps() {
    local -n old_ref=${1}; shift
    local -n new_ref=${1}; shift
    local deps_idx=${1}; shift
    local dr_var_name=${1}; shift

    local old_group_name=${old_ref[${deps_idx}]} new_group_name=${new_ref[${deps_idx}]}
    local -a dd_old_flattened_list=() dd_new_flattened_list=()
    __mcdl_flatten_group "${old_group_name}" dd_old_flattened_list
    __mcdl_flatten_group "${new_group_name}" dd_new_flattened_list

    local -a dd_common_items=()

    lcs_run dd_old_flattened_list dd_new_flattened_list dd_common_items __mcdl_flattened_group_item_eq

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
                    diff_report_append "${dr_var_name}" "dropped license ${v1@Q}"
                    ;;
                'p')
                    local p_str=''
                    pds_to_string "${v1}" p_str
                    diff_report_append "${dr_var_name}" "dropped a dependency ${p_str@Q}"
                    ;;
                'o'|'c'|'i')
                    if [[ -z ${check_todo} ]]; then
                        diff_report_append "${dr_var_name}" "TODO: check the diff in ${deps_idx@Q}"
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
                    diff_report_append "${dr_var_name}" "added license ${v2@Q}"
                    ;;
                'p')
                    local p_str=''
                    pds_to_string "${v2}" p_str
                    diff_report_append "${dr_var_name}" "added a dependency ${p_str@Q}"
                    ;;
                'o'|'c'|'i')
                    if [[ -z ${check_todo} ]]; then
                        diff_report_append "${dr_var_name}" "TODO: check the diff in ${deps_idx@Q}"
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
                pds_diff "${item1#*:}" "${item2#*:}" "${dr_var_name}"
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
    unset "${dd_common_items[@]}"

    idx1=${#dd_old_flattened_list[@]}
    idx2=${#dd_new_flattened_list[@]}
    while [[ ${last_idx1} -lt ${idx1} ]]; do
        local item1=${dd_old_flattened_list["${last_idx1}"]}
        local t1=${item1%:*} v1=${item1#*:}
        case ${t1} in
            'l')
                diff_report_append "${dr_var_name}" "dropped license ${v1@Q}"
                ;;
            'p')
                local p_str=''
                pds_to_string "${v1}" p_str
                diff_report_append "${dr_var_name}" "dropped a dependency ${p_str@Q}"
                ;;
            'o'|'c'|'i')
                if [[ -z ${check_todo} ]]; then
                    diff_report_append "${dr_var_name}" "TODO: check the diff in ${deps_idx@Q}"
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
                diff_report_append "${dr_var_name}" "added license ${v2@Q}"
                ;;
            'p')
                local p_str=''
                pds_to_string "${v2}" p_str
                diff_report_append "${dr_var_name}" "added a dependency ${p_str@Q}"
                ;;
            'o'|'c'|'i')
                if [[ -z ${check_todo} ]]; then
                    diff_report_append "${dr_var_name}" "TODO: check the diff in ${deps_idx@Q}"
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
    local dr_var_name=${1}; shift

    diff_eapi "${old_var_name}" "${new_var_name}" "${dr_var_name}"
    diff_keywords "${old_var_name}" "${new_var_name}" "${dr_var_name}"
    diff_iuse "${old_var_name}" "${new_var_name}" "${dr_var_name}"

    local -i idx
    for idx in ${PCF_BDEPEND_IDX} ${PCF_DEPEND_IDX} ${PCF_IDEPEND_IDX} ${PCF_PDEPEND_IDX} ${PCF_RDEPEND_IDX} ${PCF_LICENSE_IDX}; do
        diff_deps "${old_var_name}" "${new_var_name}" ${idx} "${dr_var_name}"
    done
}

fi
