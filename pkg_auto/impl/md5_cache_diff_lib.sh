#!/bin/bash

if [[ -z ${__MD5_CACHE_DIFF_LIB_SH_INCLUDED__:-} ]]; then
__MD5_CACHE_DIFF_LIB_SH_INCLUDED__=x

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"
source "${PKG_AUTO_IMPL_DIR}/lcs.sh"
source "${PKG_AUTO_IMPL_DIR}/md5_cache_lib.sh"
source "${PKG_AUTO_IMPL_DIR}/mvm.sh"

declare -gri DR_INDENT_IDX=0 DR_LINES_IDX=1

function diff_report_declare() {
    local name=${1}; shift

    declare -ga "${name}=( 0 EMPTY_ARRAY )"
}

function diff_report_unset() {
    local dr_var_name=${1}; shift
    local -n dr_ref=${dr_var_name}
    local lines_var_name=${dr_ref[DR_LINES_IDX]}

    if [[ ${lines_var_name} != EMPTY_ARRAY ]]; then
        unset "${lines_var_name}"
    fi
    unset -n dr_ref
    unset "${dr_var_name}"
}

function diff_report_is_empty() {
    local -n dr_ref=${1}; shift
    local -n out_ref=${1}; shift

    local -n lines_ref=${dr_ref[DR_LINES_IDX]}
    if [[ ${#lines_ref[@]} -eq 0 ]]; then
        out_ref=x
    else
        out_ref=
    fi
}

function diff_report_append() {
    local dr_var_name=${1}; shift
    local line=${1}; shift

    local -n dr_ref=${dr_var_name}
    local dra_lines_name=${dr_ref[DR_LINES_IDX]}
    if [[ ${dra_lines_name} == EMPTY_ARRAY ]]; then
        gen_varname dra_lines_name
        declare -ga "${dra_lines_name}=()"
        dr_ref[DR_LINES_IDX]=${dra_lines_name}
    fi

    local -i indent
    indent=${dr_ref[DR_INDENT_IDX]}

    local indent_line=${indent}:${line}
    pkg_debug "  ${indent_line} (${dr_var_name@Q})"

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

function diff_report_append_diff_report() {
    local dr_var_name=${1}; shift
    local -n dr_ref2=${1}; shift

    local -n dr_ref=${dr_var_name}
    local dra_lines_name=${dr_ref[DR_LINES_IDX]}
    if [[ ${dra_lines_name} == EMPTY_ARRAY ]]; then
        gen_varname dra_lines_name
        declare -ga "${dra_lines_name}=()"
        dr_ref[DR_LINES_IDX]=${dra_lines_name}
    fi

    local -i indent
    indent=${dr_ref[DR_INDENT_IDX]}
    local -n lines_ref=${dra_lines_name}

    local -n lines2_ref=${dr_ref2[DR_LINES_IDX]}
    local indent_line2 line2
    local -i indent2
    for indent_line2 in "${lines2_ref[@]}"; do
        indent2=${indent_line2%%:*}
        line2=${indent_line2#*:}
        indent2=$((indent + indent2))
        indent_line2=${indent2}:${line2}
        pkg_debug "  ${indent_line2} (${dr_var_name@Q})"
        lines_ref+=( "${indent_line2}" )
    done
}

function diff_report_indent() {
    local -n dr_ref=${1}; shift

    ((++dr_ref[DR_INDENT_IDX]))
}

function diff_report_dedent() {
    local -n dr_ref=${1}; shift

    ((dr_ref[DR_INDENT_IDX]--))
}

function diff_eapi() {
    local -n old_ref=${1}; shift
    local -n new_ref=${1}; shift
    local dr_var_name=${1}; shift

    local old_eapi=${old_ref[PCF_EAPI_IDX]}
    local new_eapi=${new_ref[PCF_EAPI_IDX]}

    if [[ ${old_eapi} != "${new_eapi}" ]]; then
        diff_report_append "${dr_var_name}" "EAPI changed from ${old_eapi@Q} to ${new_eapi@Q}"
    fi
}

function diff_iuse() {
    local -n old_ref=${1}; shift
    local -n new_ref=${1}; shift
    local dr_var_name=${1}; shift

    local old_iuses_var_name=${old_ref[PCF_IUSE_IDX]}
    local new_iuses_var_name=${new_ref[PCF_IUSE_IDX]}

    local -A old_map=() new_map=() removed same added

    local -n old_iuses_ref=${old_iuses_var_name} new_iuses_ref=${new_iuses_var_name}

    local -i idx=0
    local iuse_var_name name
    for iuse_var_name in "${old_iuses_ref[@]}"; do
        # shellcheck disable=SC2178 # shellcheck does not grok references
        local -n iuse_ref=${iuse_var_name}
        # shellcheck disable=SC2034 # shellcheck does not grok references
        name=${iuse_ref[IUSE_NAME_IDX]}
        old_map["${name}"]=${idx}
        unset -n iuse_ref
        ((++idx))
    done

    idx=0
    for iuse_var_name in "${new_iuses_ref[@]}"; do
        # shellcheck disable=SC2178 # shellcheck does not grok references
        local -n iuse_ref=${iuse_var_name}
        name=${iuse_ref[IUSE_NAME_IDX]}
        new_map["${name}"]=${idx}
        unset -n iuse_ref
        ((++idx))
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
        local -n old_iuse_ref=${old_iuses_ref[${old_idx}]} new_iuse_ref=${new_iuses_ref[${new_idx}]}
        old_mode=${old_iuse_ref[IUSE_MODE_IDX]}
        new_mode=${new_iuse_ref[IUSE_MODE_IDX]}
        unset -n new_iuse_ref old_iuse_ref
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

    local old_kws_var_name=${old_ref[PCF_KEYWORDS_IDX]}
    local new_kws_var_name=${new_ref[PCF_KEYWORDS_IDX]}

    local -n old_kws_ref=${old_kws_var_name}
    local -n new_kws_ref=${new_kws_var_name}

    if [[ ${#old_kws_ref[@]} -ne ${#new_kws_ref[@]} ]]; then
        fail 'keywords number should always be the same'
    fi

    local index old_name new_name old_level new_level level_str
    for (( index=0; index < ${#old_kws_ref[@]}; ++index )); do
        local -n old_kw_ref=${old_kws_ref["${index}"]}
        local -n new_kw_ref=${new_kws_ref["${index}"]}
        old_name=${old_kw_ref[KW_NAME_IDX]}
        new_name=${new_kw_ref[KW_NAME_IDX]}
        if [[ ${old_name} != "${new_name}" ]]; then
            fail 'keywords of the same name should always have the same index'
        fi
        old_level=${old_kw_ref[KW_LEVEL_IDX]}
        new_level=${new_kw_ref[KW_LEVEL_IDX]}
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
    local -n group_items_ref=${group_ref[GROUP_ITEMS_IDX]}

    case ${group_ref[GROUP_TYPE_IDX]} in
        ${GROUP_ALL_OF})
            local name=${group_ref[GROUP_USE_IDX]}
            if [[ -n ${name} ]]; then
                case ${group_ref[GROUP_ENABLED_IDX]} in
                    ${GROUP_USE_ENABLED})
                        :
                        ;;
                    ${GROUP_USE_DISABLED})
                        name="!${name}"
                        ;;
                esac
                name+='?'
                flattened_items_ref+=( "i:${name}" )
            fi
            unset name
            ;;
        ${GROUP_ANY_OF})
            flattened_items_ref+=( "i:||" )
            ;;
    esac
    flattened_items_ref+=( "o:(" )

    local item_var_name item_type
    for item_var_name in "${group_items_ref[@]}"; do
        local -n item_ref=${item_var_name}
        item_type=${item_ref:0:1}
        case ${item_type} in
            'e')
                # do not add empty items to the list
                :
                ;;
            'g')
                local subgroup_name=${item_ref:2}
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

function __mcdl_flattened_group_item_score() {
    local -n score_ref=${1}; shift

    score_ref=3

    if [[ ${#} -eq 0 ]]; then
        return
    fi

    local i1=${1}; shift
    local i2=${1}; shift

    local t1=${i1:0:1}
    local t2=${i2:0:1}

    if [[ ${t1} != "${t2}" ]]; then
        score_ref=0
        return
    fi

    local v1=${i1:2}
    local v2=${i2:2}
    case ${t1} in
        'l'|'i')
            [[ "${v1}" = "${v2}" ]] || score_ref=0
            ;;
        'p')
            local -n p1_ref=${v1} p2_ref=${v2}
            local n1=${p1_ref[PDS_NAME_IDX]} n2=${p2_ref[PDS_NAME_IDX]}
            if [[ "${n1}" = "${n2}" ]]; then
                local p1_str p2_str
                pds_to_string "${v1}" p1_str
                pds_to_string "${v2}" p2_str
                [[ "${p1_str}" = "${p2_str}" ]] || score_ref=1
                unset p2_str p1_str
            else
                score_ref=0
            fi
            unset n2 n1
            unset -n p2_ref p1_ref
            ;;
        'o'|'c')
            # parens are the same everywhere
            :
            ;;
        *)
            fail "item ${i1} or ${i2} is bad"
            ;;
    esac
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

function iuse_stack_to_string() {
    local -n stack_ref=${1}; shift
    local -n str_ref=${1}; shift

    str_ref=''
    # we always ignore the first element - it's a name of the toplevel
    # unnamed group, so stack of length 1 means no groups were
    # encountered
    if [[ ${#stack_ref[@]} -le 1 ]]; then
        return 0
    fi

    local iuse
    # we always ignore the first element - it's a name of the toplevel
    # unnamed group
    for iuse in "${stack_ref[@]:1}"; do
        str_ref+="${iuse@Q} -> "
    done
    str_ref=${str_ref:0:$((${#str_ref} - 4))}
}

function pds_diff() {
    local -n old_pds_ref=${1}; shift
    local -n new_pds_ref=${1}; shift
    local old_stack_name=${1}; shift
    local new_stack_name=${1}; shift
    local dr_var_name=${1}; shift

    local name=${new_pds_ref[PDS_NAME_IDX]}

    local old_iuses new_iuses
    iuse_stack_to_string "${old_stack_name}" old_iuses
    iuse_stack_to_string "${new_stack_name}" new_iuses

    diff_report_declare local_pds_dr

    if [[ ${old_iuses} != "${new_iuses}" ]]; then
        if [[ -z ${new_iuses} ]]; then
            diff_report_append local_pds_dr "dropped all USE conditionals"
        else
            diff_report_append local_pds_dr "USE conditionals changed to ${new_iuses}"
        fi
    fi

    local -i old_blocks=${old_pds_ref[PDS_BLOCKS_IDX]} new_blocks=${new_pds_ref[PDS_BLOCKS_IDX]}
    if [[ old_blocks -ne new_blocks ]]; then
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
        diff_report_append local_pds_dr "changed to ${block} block"
        unset block
    fi

    local old_op=${old_pds_ref[PDS_OP_IDX]} old_ver=${old_pds_ref[PDS_VER_IDX]} new_op=${new_pds_ref[PDS_OP_IDX]} new_ver=${new_pds_ref[PDS_VER_IDX]}
    if [[ ${old_op} != "${new_op}" || ${old_ver} != ${new_ver} ]]; then
        if [[ -z ${new_op} && -z ${new_ver} ]]; then
            diff_report_append local_pds_dr "dropped version constraint"
        elif [[ -z ${old_op} && -z ${old_ver} ]]; then
            diff_report_append local_pds_dr "added version constraint ${new_op}${new_ver}"
        else
            diff_report_append local_pds_dr "changed version constraint from ${old_op}${old_ver} to ${new_op}${new_ver}"
        fi
    fi

    local old_slot=${old_pds_ref[PDS_SLOT_IDX]} new_slot=${new_pds_ref[PDS_SLOT_IDX]}
    if [[ ${old_slot} != "${new_slot}" ]]; then
        if [[ -z ${new_slot} ]]; then
            diff_report_append local_pds_dr "dropped slot constraint"
        elif [[ -z ${old_slot} ]]; then
            diff_report_append local_pds_dr "added slot constraint ${new_slot}"
        else
            diff_report_append local_pds_dr "changed slot constraint from ${old_slot} to ${new_slot}"
        fi
    fi

    local -n old_urs_ref=${old_pds_ref[PDS_UR_IDX]} new_urs_ref=${new_pds_ref[PDS_UR_IDX]}
    local -A old_name_index=() new_name_index=()

    local ur_name use_name
    local -i idx=0
    for ur_name in "${old_urs_ref[@]}"; do
        local -n ur_ref=${ur_name}
        use_name=${ur_ref[UR_NAME_IDX]}
        old_name_index["${use_name}"]=${idx}
        ((++idx))
        unset -n ur_ref
    done

    idx=0
    for ur_name in "${new_urs_ref[@]}"; do
        local -n ur_ref=${ur_name}
        use_name=${ur_ref[UR_NAME_IDX]}
        new_name_index["${use_name}"]=${idx}
        ((++idx))
        unset -n ur_ref
    done

    local -A only_old_urs=() only_new_urs=() common_urs=()
    sets_split old_name_index new_name_index only_old_urs only_new_urs common_urs
    for use_name in "${!only_old_urs[@]}"; do
        diff_report_append local_pds_dr "dropped ${use_name} use requirement"
    done
    local pd_mode_str pd_pretend_str
    for use_name in "${!only_new_urs[@]}"; do
        idx=${new_name_index["${use_name}"]}
        local -n ur_ref=${new_urs_ref[${idx}]}
        __mcdl_ur_mode_description "${ur_ref[UR_MODE_IDX]}" pd_mode_str
        __mcdl_ur_pretend_description "${ur_ref[UR_PRETEND_IDX]}" pd_pretend_str
        diff_report_append local_pds_dr "added ${use_name} use ${pd_mode_str} requirement (${pd_pretend_str})"
        unset -n ur_ref
    done

    local -i old_idx new_idx
    local old_mode new_mode old_pretend new_pretend pd_old_mode_str pd_new_mode_str pd_old_pretend_str pd_new_pretend_str
    for use_name in "${!common_urs[@]}"; do
        old_idx=${old_name_index["${use_name}"]}
        new_idx=${new_name_index["${use_name}"]}

        local -n old_ur_ref=${old_urs_ref[${old_idx}]} new_ur_ref=${new_urs_ref[${new_idx}]}
        old_mode=${old_ur_ref[UR_MODE_IDX]}
        new_mode=${new_ur_ref[UR_MODE_IDX]}
        if [[ ${old_mode} != ${new_mode} ]]; then
            __mcdl_ur_mode_description "${old_mode}" pd_old_mode_str
            __mcdl_ur_mode_description "${new_mode}" pd_new_mode_str
            diff_report_append local_pds_dr "mode of use requirement on ${use_name} changed from ${pd_old_mode_str} to ${pd_new_mode_str}"
        fi

        old_pretend=${old_ur_ref[UR_PRETEND_IDX]}
        new_pretend=${new_ur_ref[UR_PRETEND_IDX]}
        if [[ ${old_pretend} != "${new_pretend}" ]]; then
            __mcdl_ur_pretend_description "${old_pretend}" pd_old_pretend_str
            __mcdl_ur_pretend_description "${new_pretend}" pd_new_pretend_str
            diff_report_append local_pds_dr "pretend mode of use requirement on ${use_name} changed from ${pd_old_pretend_str@Q} to ${pd_new_pretend_str@Q}"
        fi
        unset -n new_ur_ref old_ur_ref
    done

    local local_pds_dr_empty
    diff_report_is_empty local_pds_dr local_pds_dr_empty
    if [[ -z ${local_pds_dr_empty} ]]; then
        local iuse_str=''
        if [[ -n ${old_iuses} ]]; then
            iuse_str=" with USE conditionals ${old_iuses}"
        fi

        local block_str=''
        local -i new_blocks=${new_pds_ref[PDS_BLOCKS_IDX]}
        case ${new_blocks} in
            ${PDS_NO_BLOCK})
                block_str=''
                ;;
            ${PDS_WEAK_BLOCK})
                block_str=' weak blocker'
                ;;
            ${PDS_STRONG_BLOCK})
                block_str=' strong blocker'
                ;;
        esac

        diff_report_append "${dr_var_name}" "changes for ${name}${block_str}${iuse_str}:"
        diff_report_indent "${dr_var_name}"
        diff_report_append_diff_report "${dr_var_name}" local_pds_dr
        diff_report_dedent "${dr_var_name}"
    fi
    diff_report_unset local_pds_dr
}

function dsg_merge_and_sort_tagged_subgroups() {
    local -n empty_subgroup_item_name_ref=${1}; shift
    local -n subgroup_tag_to_named_subgroup_item_names_map_ref=${1}; shift
    local -n any_of_subgroup_item_names_ref=${1}; shift
    local subgroup_tag=${1}; shift
    # skip the mvc name, the group names will be the rest of the
    # args
    shift
    # rest are subgroup item names

    if [[ ${#} -eq 0 ]]; then return 0; fi

    local subgroup_item_name subgroup_name other_subgroup_item_name other_subgroup_name
    if [[ ${subgroup_tag} = '@any-of@' ]]; then
        for subgroup_item_name; do
            local -n item_ref=${subgroup_item_name}
            subgroup_name=${item_ref:2}
            unset -n item_ref
            sort_group "${subgroup_name}"
            any_of_subgroup_item_names_ref+=( "${subgroup_item_name}" )
        done
    else
        subgroup_item_name=${1}; shift
        local -n item_ref=${subgroup_item_name}
        subgroup_name=${item_ref:2}
        unset -n item_ref
        local other_subgroup_items_name
        for other_subgroup_item_name; do
            local -n item_ref=${other_subgroup_item_name}
            other_subgroup_name=${item_ref:2}
            unset -n item_ref
            local -n other_subgroup_ref=${other_subgroup_name}
            other_subgroup_items_name=${other_subgroup_ref[GROUP_ITEMS_IDX]}
            local -n other_subgroup_items_ref=${other_subgroup_items_name}
            group_add_items "${subgroup_name}" "${other_subgroup_items_ref[@]}"
            unset -n other_subgroup_items_ref
            other_subgroup_ref[GROUP_ITEMS_IDX]='EMPTY_ARRAY'
            unset -n other_subgroup_ref
            unset "${other_subgroup_items_name}"
            item_unset "${other_subgroup_item_name}"
        done
        sort_group "${subgroup_name}"
        if [[ ${subgroup_tag} = '@empty@' ]]; then
            empty_subgroup_item_name_ref=${subgroup_item_name}
        else
            subgroup_tag_to_named_subgroup_item_names_map_ref["${subgroup_tag}"]=${subgroup_item_name}
        fi
    fi
}

function sort_group() {
    local group_name=${1}; shift

    local -n group_ref=${group_name}
    local -a subgroup_item_names license_item_names pds_item_names=()
    local -n items_ref=${group_ref[GROUP_ITEMS_IDX]}

    subgroup_item_names=()
    license_item_names=()
    pds_item_names=()

    if [[ ${#items_ref[@]} -eq 0 ]]; then
        return 0
    fi

    local item_name item_type
    for item_name in "${items_ref[@]}"; do
        local -n item=${item_name}
        item_type=${item:0:1}
        unset -n item
        case ${item_type} in
            e)
                # these won't show up in sorted group
                :
                ;;
            g)
                subgroup_item_names+=( "${item_name}" )
                ;;
            l)
                license_item_names+=( "${item_name}" )
                ;;
            p)
                pds_item_names+=( "${item_name}" )
                ;;
        esac
    done
    unset item_name item_type
    items_ref=()
    unset -n items_ref group_ref

    ##
    ## add sorted pds into group
    ##

    if [[ ${#pds_item_names[@]} -gt 0 ]]; then
        # the package name may appear more than one time in the same
        # group, this happens for ranged deps (e.g >=2.0, <3.0)
        local pds_item_name
        local pds_name pkg_name counted_pkg_name
        local -i pkg_name_count
        local -A pkg_name_to_count_map=()
        local -a pkg_names=()
        local -A pkg_name_to_item_name_map=()
        for pds_item_name in "${pds_item_names[@]}"; do
            local -n item_ref=${pds_item_name}
            pds_name=${item_ref:2}
            unset -n item_ref
            local -n pds_ref=${pds_name}
            pkg_name=${pds_ref[PDS_NAME_IDX]}
            unset -n pds_ref
            pkg_name_count=${pkg_name_to_count_map["${pkg_name}"]:-0}
            counted_pkg_name="${pkg_name}^${pkg_name_count}"
            ((++pkg_name_count))
            pkg_name_to_count_map["${pkg_name}"]=${pkg_name_count}
            pkg_names+=( "${counted_pkg_name}" )
            pkg_name_to_item_name_map["${counted_pkg_name}"]=${pds_item_name}
        done
        local -a sorted_pkg_names
        mapfile -t sorted_pkg_names < <(printf '%s\n' "${pkg_names[@]}" | sort -t '^' -k 1,1 -k2n,2)

        for pkg_name in "${sorted_pkg_names[@]}"; do
            pds_item_name=${pkg_name_to_item_name_map["${pkg_name}"]}
            group_add_item "${group_name}" "${pds_item_name}"
        done
        unset sorted_pkg_names pkg_name_to_item_name_map pkg_names pkg_name_to_count_map pkg_name_count pkg_name_count counted_pkg_name pkg_name pds_name pds_item_name
    fi

    ##
    ## add sorted licenses into group
    ##

    if [[ ${#license_item_names[@]} -gt 0 ]]; then
        local -A license_to_item_name_map=()

        local license_item_name license
        for license_item_name in "${license_item_names[@]}"; do
            local -n item_ref=${license_item_name}
            license=${item_ref:2}
            unset -n item_ref
            license_to_item_name_map["${license}"]=${license_item_name}
        done
        local -a sorted_licenses
        mapfile -t sorted_licenses < <(printf '%s\n' "${!license_to_item_name_map[@]}" | sort)
        for license in "${sorted_licenses[@]}"; do
            license_item_name=${license_to_item_name_map["${license}"]}
            group_add_item "${group_name}" "${license_item_name}"
        done

        unset sorted_licenses license_item_name license license_to_item_name_map
    fi

    ##
    ## add sorted subgroups into group
    ##
    if [[ ${#subgroup_item_names[@]} -gt 0 ]]; then
        # - collect group names based on their type, use name and enabled use
        #   - unnamed all-of go first (tag: empty)
        #   - named all-of go next (tag: use name + enabled use)
        #   - any-of go each separately (tag: any-of)
        # - merge all-of groups with the same tag
        # - sort each group and add to main group
        local subgroup_item_name subgroup_name subgroup_type subgroup_use subgroup_tag subgroup_use_mode
        local dsg_tagged_subgroups_item_names_array_mvm_name
        gen_varname dsg_tagged_subgroups_item_names_array_mvm_name
        mvm_declare "${dsg_tagged_subgroups_item_names_array_mvm_name}"
        for subgroup_item_name in "${subgroup_item_names[@]}"; do
            local -n item_ref=${subgroup_item_name}
            subgroup_name=${item_ref:2}
            unset -n item_ref
            local -n subgroup_ref=${subgroup_name}
            subgroup_type=${subgroup_ref[GROUP_TYPE_IDX]}
            case ${subgroup_type} in
                ${GROUP_ALL_OF})
                    subgroup_use=${subgroup_ref[GROUP_USE_IDX]}
                    if [[ -z ${subgroup_use} ]]; then
                        subgroup_tag='@empty@'
                    else
                        subgroup_use_mode=${subgroup_ref[GROUP_ENABLED_IDX]}
                        case ${subgroup_use_mode} in
                            ${GROUP_USE_ENABLED})
                                subgroup_tag='+'
                                ;;
                            ${GROUP_USE_DISABLED})
                                subgroup_tag='-'
                                ;;
                        esac
                        subgroup_tag+=${subgroup_use}
                    fi
                    ;;
                ${GROUP_ANY_OF})
                    subgroup_tag="@any-of@"
                    ;;
            esac
            unset -n subgroup_ref
            mvm_add "${dsg_tagged_subgroups_item_names_array_mvm_name}" "${subgroup_tag}" "${subgroup_item_name}"
        done
        unset subgroup_use_mode subgroup_tag subgroup_use subgroup_type subgroup_name subgroup_item_name

        local empty_subgroup_item_name=''
        local -A subgroup_tag_to_named_subgroup_item_names_map=()
        local -a any_of_subgroup_item_names=()
        mvm_iterate "${dsg_tagged_subgroups_item_names_array_mvm_name}" dsg_merge_and_sort_tagged_subgroups \
                    empty_subgroup_item_name \
                    subgroup_tag_to_named_subgroup_item_names_map \
                    any_of_subgroup_item_names
        mvm_unset "${dsg_tagged_subgroups_item_names_array_mvm_name}"

        if [[ -n ${empty_subgroup_item_name} ]]; then
            group_add_item "${group_name}" "${empty_subgroup_item_name}"
        fi
        if [[ ${#subgroup_tag_to_named_subgroup_item_names_map[@]} -gt 0 ]]; then
            local -a sorted_subgroup_tags
            local subgroup_tag subgroup_item_name
            mapfile -t sorted_subgroup_tags < <(printf '%s\n' "${!subgroup_tag_to_named_subgroup_item_names_map[@]}" | sort)
            for subgroup_tag in "${sorted_subgroup_tags[@]}"; do
                if [[ ${subgroup_tag:0:1} = '@' && ${subgroup_tag: -1:1} = '@' ]]; then
                    continue
                fi
                subgroup_item_name=${subgroup_tag_to_named_subgroup_item_names_map["${subgroup_tag}"]}
                group_add_item "${group_name}" "${subgroup_item_name}"
            done
            unset subgroup_item_name subgroup_tag sorted_subgroup_tags
        fi
        group_add_items "${group_name}" "${any_of_subgroup_item_names[@]}"
    fi
}

function iuse_stack_to_string_ps() {
    local stack_name=${1}; shift
    local -n str_ref=${1}; shift
    local prefix=${1}; shift
    local suffix=${1}; shift

    local tmp_str
    iuse_stack_to_string "${stack_name}" tmp_str

    if [[ -n ${tmp_str} ]]; then
        str_ref="${prefix}${tmp_str}${suffix}"
    else
        str_ref=''
    fi
}

function debug_group() {
    local group_name=${1}; shift
    local label=${1}; shift

    if pkg_debug_enabled; then
        local dg_group_str
        group_to_string "${group_name}" dg_group_str
        pkg_debug_print "${label}: ${dg_group_str}"
    fi
}

function debug_flattened_list() {
    local list_name=${1}; shift
    local label=${1}; shift

    if pkg_debug_enabled; then
        local item item_type
        local -n list_ref=${list_name}
        pkg_debug_print "${label}:"
        for item in "${list_ref[@]}"; do
            item_type=${item:0:1}
            case ${item_type} in
                'i'|'o'|'c'|'l')
                    pkg_debug_print "  ${item}"
                    ;;
                'p')
                    local dfl_pds_str
                    pds_to_string "${item:2}" dfl_pds_str
                    pkg_debug_print "  ${item} (${dfl_pds_str})"
                    unset dfl_pds_str
                    ;;
            esac
        done
        unset -n list_ref
    fi
}

function debug_diff() {
    local -n dd_old_list_ref=${1}; shift
    local -n dd_new_list_ref=${1}; shift
    local -n dd_common_list_ref=${1}; shift

    if ! pkg_debug_enabled; then
        return 0
    fi

    pkg_debug_print "diff between old and new flattened lists"
    local -i last_idx1=0 last_idx2=0 idx1 idx2
    local ci_name
    for ci_name in "${dd_common_list_ref[@]}"; do
        local -n ci_ref=${ci_name}
        idx1=${ci_ref[LCS_IDX1_IDX]}
        idx2=${ci_ref[LCS_IDX2_IDX]}
        unset -n ci_ref
        while [[ ${last_idx1} -lt ${idx1} ]]; do
            local item1=${dd_old_list_ref["${last_idx1}"]}
            local t1=${item1:0:1} v1=${item1:2}
            case ${t1} in
                'l'|'i'|'o'|'c')
                    pkg_debug_print "  -${v1}"
                    ;;
                'p')
                    local p_str
                    pds_to_string "${v1}" p_str
                    pkg_debug_print "  -${p_str}"
                    unset p_str
                    ;;
                *)
                    fail "item ${item1} is bad"
                    ;;
            esac
            unset v1 t1 item1
            ((++last_idx1))
        done
        while [[ ${last_idx2} -lt ${idx2} ]]; do
            local item2=${dd_new_list_ref["${last_idx2}"]}
            local t2=${item2:0:1} v2=${item2:2}
            case ${t2} in
                'l'|'i'|'o'|'c')
                    pkg_debug_print "  +${v2}"
                    ;;
                'p')
                    local p_str
                    pds_to_string "${v2}" p_str
                    pkg_debug_print "  +${p_str}"
                    unset p_str
                    ;;
                *)
                    fail "item ${item2} is bad"
                    ;;
            esac
            unset v2 t2 item2
            ((++last_idx2))
        done

        local item1=${dd_old_list_ref["${idx1}"]} item2=${dd_new_list_ref["${idx2}"]}
        local t1=${item1:0:1} v1=${item1:2} t2=${item2:0:1} v2=${item2:2}

        case ${t1} in
            'l'|'i'|'o'|'c')
                pkg_debug_print "   ${v2}"
                ;;
            'p')
                local p1_str p2_str
                pds_to_string "${v1}" p1_str
                pds_to_string "${v2}" p2_str
                if [[ "${p1_str}" != "${p2_str}" ]]; then
                    pkg_debug_print "   ${p1_str} -> ${p2_str}"
                else
                    pkg_debug_print "   ${p1_str}"
                fi
                unset p2_str p1_str
                ;;
            *)
                fail "item ${item1} or ${item2} is bad"
                ;;
        esac

        unset v2 t2 item2
        unset v1 t1 item1
        ((++last_idx1))
        ((++last_idx2))
    done

    idx1=${#dd_old_list_ref[@]}
    idx2=${#dd_new_list_ref[@]}
    while [[ ${last_idx1} -lt ${idx1} ]]; do
        local item1=${dd_old_list_ref["${last_idx1}"]}
        local t1=${item1:0:1} v1=${item1:2}
        case ${t1} in
            'l'|'i'|'o'|'c')
                pkg_debug_print "  -${v1}"
                ;;
            'p')
                local p_str
                pds_to_string "${v1}" p_str
                pkg_debug_print "  -${p_str}"
                unset p_str
                ;;
            *)
                fail "item ${item1} is bad"
                ;;
        esac
        unset v1 t1 item1
        ((++last_idx1))
    done
    while [[ ${last_idx2} -lt ${idx2} ]]; do
        local item2=${dd_new_list_ref["${last_idx2}"]}
        local t2=${item2:0:1} v2=${item2:2}
        case ${t2} in
            'l'|'i'|'o'|'c')
                pkg_debug_print "  +${v2}"
                ;;
            'p')
                local p_str
                pds_to_string "${v2}" p_str
                pkg_debug_print "  +${p_str}"
                unset p_str
                ;;
            *)
                fail "item ${item2} is bad"
                ;;
        esac
        unset v2 t2 item2
        ((++last_idx2))
    done
}

function debug_iuse_stack() {
    local iuse_stack_name=${1}; shift
    local label=${1}; shift

    if pkg_debug_enabled; then
        local dis_str
        iuse_stack_to_string "${iuse_stack_name}" dis_str
        pkg_debug_print "${label}: ${dis_str}"
    fi
}

function diff_deps() {
    local -n old_ref=${1}; shift
    local -n new_ref=${1}; shift
    local deps_idx=${1}; shift
    local dr_var_name=${1}; shift

    local label
    case ${deps_idx} in
        ${PCF_BDEPEND_IDX})
            label='build dependencies'
            ;;
        ${PCF_DEPEND_IDX})
            label='dependencies'
            ;;
        ${PCF_IDEPEND_IDX})
            label='install dependencies'
            ;;
        ${PCF_PDEPEND_IDX})
            label='post dependencies'
            ;;
        ${PCF_RDEPEND_IDX})
            label='runtime dependencies'
            ;;
        ${PCF_LICENSE_IDX})
            label='licenses'
            ;;
        *)
            fail "bad cache file index ${deps_idx@Q}"
            ;;
    esac

    local old_group_name=${old_ref[${deps_idx}]} new_group_name=${new_ref[${deps_idx}]}
    local -a dd_old_flattened_list=() dd_new_flattened_list=()

    group_declare old_sorted_group
    group_copy old_sorted_group "${old_group_name}"
    debug_group old_sorted_group "copy of old ${label} group"
    sort_group old_sorted_group
    debug_group old_sorted_group "sorted old ${label} group"

    group_declare new_sorted_group
    group_copy new_sorted_group "${new_group_name}"
    debug_group new_sorted_group "copy of new ${label} group"
    sort_group new_sorted_group
    debug_group old_sorted_group "sorted new ${label} group"

    __mcdl_flatten_group old_sorted_group dd_old_flattened_list
    __mcdl_flatten_group new_sorted_group dd_new_flattened_list

    debug_flattened_list dd_old_flattened_list "flattened old ${label} group"
    debug_flattened_list dd_new_flattened_list "flattened new ${label} group"

    local -a dd_common_items=()

    lcs_run dd_old_flattened_list dd_new_flattened_list dd_common_items __mcdl_flattened_group_item_score

    diff_report_declare local_dr

    debug_diff dd_old_flattened_list dd_new_flattened_list dd_common_items

    local -a old_iuse_stack=() new_iuse_stack=()
    # a stack of counters for naming unnamed groups like
    #
    # || ( ( a/b-1 c/d-1 ) ( a/b-2 c/d-2 ) )
    #
    # The "( a/b-1 c/d-1 )" and "( a/b-2 c/d-2 )" groups are unnamed
    # within the "||" group.
    local old_group_unnamed_counter_stack=( 0 ) new_group_unnamed_counter_stack=( 0 )
    local -i last_idx1=0 last_idx2=0 idx1 idx2
    local ci_name
    local prev_item1='e:' prev_item2='e:'
    for ci_name in "${dd_common_items[@]}"; do
        local -n ci_ref=${ci_name}
        idx1=${ci_ref[LCS_IDX1_IDX]}
        idx2=${ci_ref[LCS_IDX2_IDX]}
        unset -n ci_ref
        while [[ ${last_idx1} -lt ${idx1} ]]; do
            local item1=${dd_old_flattened_list["${last_idx1}"]}
            pkg_debug "old item ${item1@Q}"
            local t1=${item1:0:1} v1=${item1:2}
            case ${t1} in
                'l')
                    local use_str
                    iuse_stack_to_string_ps old_iuse_stack use_str ' for USE ' ''
                    diff_report_append local_dr "dropped license ${v1@Q}${use_str}"
                    unset use_str
                    ;;
                'p')
                    local p_str use_str
                    iuse_stack_to_string_ps old_iuse_stack use_str ' for USE ' ''
                    pds_to_string "${v1}" p_str
                    diff_report_append local_dr "dropped a dependency ${p_str@Q}${use_str}"
                    unset use_str p_str
                    ;;
                'i')
                    # This will be stored in prev item and used in 'o'
                    # item handling.
                    :
                    ;;
                'o')
                    local subgroup_name
                    if [[ ${prev_item1:0:1} = 'i' ]]; then
                        subgroup_name=${prev_item1:2}
                    else
                        local -i counter=${old_group_unnamed_counter_stack[-1]}
                        ((++counter))
                        old_group_unnamed_counter_stack[-1]=${counter}
                        subgroup_name="unnamed-all-of-${counter}"
                    fi
                    old_group_unnamed_counter_stack+=( 0 )
                    old_iuse_stack+=( "${subgroup_name}" )
                    debug_iuse_stack old_iuse_stack "old iuse stack after adding ${subgroup_name@Q}"
                    unset subgroup_name
                    ;;
                'c')
                    unset 'old_iuse_stack[-1]' 'old_group_unnamed_counter_stack[-1]'
                    debug_iuse_stack old_iuse_stack "old iuse stack after dropping last name"
                    ;;
                *)
                    fail "item ${item1} is bad"
                    ;;
            esac
            prev_item1=${item1}
            unset v1 t1 item1
            ((++last_idx1))
        done
        while [[ ${last_idx2} -lt ${idx2} ]]; do
            local item2=${dd_new_flattened_list["${last_idx2}"]}
            pkg_debug "new item ${item2@Q}"
            local t2=${item2:0:1} v2=${item2:2}
            case ${t2} in
                'l')
                    local use_str
                    iuse_stack_to_string_ps new_iuse_stack use_str ' for USE ' ''
                    diff_report_append local_dr "added license ${v2@Q}${use_str}"
                    unset use_str
                    ;;
                'p')
                    local p_str use_str
                    iuse_stack_to_string_ps new_iuse_stack use_str ' for USE ' ''
                    pds_to_string "${v2}" p_str
                    diff_report_append local_dr "added a dependency ${p_str@Q}${use_str}"
                    unset use_str p_str
                    ;;
                'i')
                    # This will be stored in prev item and used in 'o'
                    # item handling.
                    :
                    ;;
                'o')
                    local subgroup_name
                    if [[ ${prev_item2:0:1} = 'i' ]]; then
                        subgroup_name=${prev_item2:2}
                    else
                        local -i counter=${new_group_unnamed_counter_stack[-1]}
                        ((++counter))
                        new_group_unnamed_counter_stack[-1]=${counter}
                        subgroup_name="unnamed-all-of-${counter}"
                    fi
                    new_group_unnamed_counter_stack+=( 0 )
                    new_iuse_stack+=( "${subgroup_name}" )
                    debug_iuse_stack new_iuse_stack "new iuse stack after adding ${subgroup_name@Q}"
                    unset subgroup_name
                    ;;
                'c')
                    unset 'new_iuse_stack[-1]' 'new_group_unnamed_counter_stack[-1]'
                    debug_iuse_stack new_iuse_stack "new iuse stack after dropping last name"
                    ;;
                *)
                    fail "item ${item2} is bad"
                    ;;
            esac
            prev_item2=${item2}
            unset v2 t2 item2
            ((++last_idx2))
        done

        local item1=${dd_old_flattened_list["${idx1}"]} item2=${dd_new_flattened_list["${idx2}"]}
        pkg_debug "old item ${item1@Q} and new item ${item2@Q}"
        local t1=${item1:0:1} v1=${item1:2} t2=${item2:0:1} v2=${item2:2}

        case ${t1} in
            'l')
                # not interesting
                :
                ;;
            'i')
                # This will be stored in prev item and used in 'o'
                # item handling.
                :
                ;;
            'o')
                local subgroup_name
                if [[ ${prev_item1:0:1} = 'i' ]]; then
                    subgroup_name=${prev_item1:2}
                else
                    local -i counter=${old_group_unnamed_counter_stack[-1]}
                    ((++counter))
                    old_group_unnamed_counter_stack[-1]=${counter}
                    subgroup_name="unnamed-all-of-${counter}"
                fi
                old_group_unnamed_counter_stack+=( 0 )
                old_iuse_stack+=( "${subgroup_name}" )
                debug_iuse_stack old_iuse_stack "old iuse stack after adding common ${subgroup_name@Q}"

                if [[ ${prev_item2:0:1} = 'i' ]]; then
                    subgroup_name=${prev_item2:2}
                else
                    local -i counter=${new_group_unnamed_counter_stack[-1]}
                    ((++counter))
                    new_group_unnamed_counter_stack[-1]=${counter}
                    subgroup_name="unnamed-all-of-${counter}"
                fi
                new_group_unnamed_counter_stack+=( 0 )
                new_iuse_stack+=( "${subgroup_name}" )
                debug_iuse_stack new_iuse_stack "new iuse stack after adding common ${subgroup_name@Q}"
                unset subgroup_name
                ;;
            'c')
                unset 'old_iuse_stack[-1]' 'old_group_unnamed_counter_stack[-1]' 'new_iuse_stack[-1]' 'new_group_unnamed_counter_stack[-1]'
                debug_iuse_stack old_iuse_stack "old iuse stack after dropping common last name"
                debug_iuse_stack new_iuse_stack "new iuse stack after dropping common last name"
                ;;
            'p')
                pds_diff "${item1:2}" "${item2:2}" old_iuse_stack new_iuse_stack local_dr
                ;;
            *)
                fail "item ${item1} or ${item2} is bad"
                ;;
        esac

        prev_item1=${item1}
        prev_item2=${item2}
        unset v2 t2 item2
        unset v1 t1 item1
        ((++last_idx1))
        ((++last_idx2))
    done
    unset "${dd_common_items[@]}"

    idx1=${#dd_old_flattened_list[@]}
    idx2=${#dd_new_flattened_list[@]}
    while [[ ${last_idx1} -lt ${idx1} ]]; do
        local item1=${dd_old_flattened_list["${last_idx1}"]}
        pkg_debug "old item ${item1@Q}"
        local t1=${item1:0:1} v1=${item1:2}
        case ${t1} in
            'l')
                local use_str
                iuse_stack_to_string_ps old_iuse_stack use_str ' for USE ' ''
                diff_report_append local_dr "dropped license ${v1@Q}${use_str}"
                unset use_str
                ;;
            'p')
                local p_str use_str
                iuse_stack_to_string_ps old_iuse_stack use_str ' for USE ' ''
                pds_to_string "${v1}" p_str
                diff_report_append local_dr "dropped a dependency ${p_str@Q}${use_str}"
                unset use_str p_str
                ;;
            'i')
                # This will be stored in prev item and used in 'o'
                # item handling.
                :
                ;;
            'o')
                local subgroup_name
                if [[ ${prev_item1:0:1} = 'i' ]]; then
                    subgroup_name=${prev_item1:2}
                else
                    local -i counter=${old_group_unnamed_counter_stack[-1]}
                    ((++counter))
                    old_group_unnamed_counter_stack[-1]=${counter}
                    subgroup_name="unnamed-all-of-${counter}"
                fi
                old_group_unnamed_counter_stack+=( 0 )
                old_iuse_stack+=( "${subgroup_name}" )
                debug_iuse_stack old_iuse_stack "old iuse stack after adding ${subgroup_name@Q}"
                unset subgroup_name
                ;;
            'c')
                unset 'old_iuse_stack[-1]' 'old_group_unnamed_counter_stack[-1]'
                debug_iuse_stack old_iuse_stack "old iuse stack after dropping last name"
                ;;
            *)
                fail "item ${item1} is bad"
                ;;
        esac
        prev_item1=${item1}
        unset v1 t1 item1
        ((++last_idx1))
    done
    while [[ ${last_idx2} -lt ${idx2} ]]; do
        local item2=${dd_new_flattened_list["${last_idx2}"]}
        pkg_debug "new item ${item2@Q}"
        local t2=${item2:0:1} v2=${item2:2}
        case ${t2} in
            'l')
                local use_str
                iuse_stack_to_string_ps new_iuse_stack use_str ' for USE ' ''
                diff_report_append local_dr "added license ${v2@Q}${use_str}"
                unset use_str
                ;;
            'p')
                local p_str use_str
                iuse_stack_to_string_ps new_iuse_stack use_str ' for USE ' ''
                pds_to_string "${v2}" p_str
                diff_report_append local_dr "added a dependency ${p_str@Q}${use_str}"
                unset use_str p_str
                ;;
            'i')
                # This will be stored in prev item and used in 'o'
                # item handling.
                :
                ;;
            'o')
                local subgroup_name
                if [[ ${prev_item2:0:1} = 'i' ]]; then
                    subgroup_name=${prev_item2:2}
                else
                    local -i counter=${new_group_unnamed_counter_stack[-1]}
                    ((++counter))
                    new_group_unnamed_counter_stack[-1]=${counter}
                    subgroup_name="unnamed-all-of-${counter}"
                fi
                new_group_unnamed_counter_stack+=( 0 )
                new_iuse_stack+=( "${subgroup_name}" )
                debug_iuse_stack new_iuse_stack "new iuse stack after adding ${subgroup_name@Q}"
                unset subgroup_name
                ;;
            'c')
                unset 'new_iuse_stack[-1]' 'new_group_unnamed_counter_stack[-1]'
                debug_iuse_stack new_iuse_stack "new iuse stack after dropping last name"
                ;;
            *)
                fail "item ${item2} is bad"
                ;;
        esac
        prev_item2=${item2}
        unset v2 t2 item2
        ((++last_idx2))
    done
    local local_dr_empty
    diff_report_is_empty local_dr local_dr_empty
    if [[ -z ${local_dr_empty} ]]; then
        diff_report_append "${dr_var_name}" "${label}:"
        diff_report_indent "${dr_var_name}"
        diff_report_append_diff_report "${dr_var_name}" local_dr
        diff_report_dedent "${dr_var_name}"
    fi
    diff_report_unset local_dr

    group_unset new_sorted_group
    group_unset old_sorted_group
}

function diff_cache_data() {
    local old_var_name=${1}; shift
    local new_var_name=${1}; shift
    local dr_var_name=${1}; shift

    diff_eapi "${old_var_name}" "${new_var_name}" "${dr_var_name}"
    diff_keywords "${old_var_name}" "${new_var_name}" "${dr_var_name}"
    diff_iuse "${old_var_name}" "${new_var_name}" "${dr_var_name}"

    local -i idx
    for idx in PCF_BDEPEND_IDX PCF_DEPEND_IDX PCF_IDEPEND_IDX PCF_PDEPEND_IDX PCF_RDEPEND_IDX PCF_LICENSE_IDX; do
        diff_deps "${old_var_name}" "${new_var_name}" ${idx} "${dr_var_name}"
    done
}

fi
