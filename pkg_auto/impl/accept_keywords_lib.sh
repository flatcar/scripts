#!/bin/bash

if [[ -z ${__ACCEPT_KEYWORDS_LIB_SH_INCLUDED__:-} ]]; then
__ACCEPT_KEYWORDS_LIB_SH_INCLUDED__=x

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

declare -gri AKIP_BLOCK_IDX_IDX=0 AKIP_ENTRY_IDX_IDX=1

function ak_idx_pair_declare() {
    struct_declare -ga "${@}" "( 0 0 )"
}

function ak_idx_pair_unset() {
    struct_unset --- "${@}"
}

declare -gri AKBE_OP_IDX=0 AKBE_QPKG_IDX=1 AKBE_VERSION_IDX=2 AKBE_KEYWORDS_IDX=3 AKBE_MARKED_FOR_REMOVAL_IDX=4

function ak_block_entry_declare() {
    struct_declare -ga "${@}" "( '' '' '' '' '' )"
}

function ak_block_entry_unset() {
    struct_unset --- "${@}"
}

declare -gri AKB_COMMENTS_IDX=0 AKB_BLOCK_ENTRIES_IDX=1 AKB_MARKED_FOR_REMOVAL_IDX=2

function ak_block_declare() {
    struct_declare -ga "${@}" "( 'EMPTY_ARRAY' 'EMPTY_ARRAY' '' )"
}

function ak_block_unset() {
    struct_unset \
        AKB_COMMENTS_IDX -a-- \
        AKB_BLOCK_ENTRIES_IDX -aak_block_entry_unset \
        --- "${@}"
}

declare -gri AK_BLOCKS_IDX=0 AK_PKG_TO_IDX_PAIR_MAP_IDX=1 AK_MODIFIED=2

function accept_keywords_declare() {
    struct_declare -ga "${@}" "( 'EMPTY_ARRAY' 'EMPTY_MAP' '' )"
}

function accept_keywords_unset() {
    struct_unset \
        AK_BLOCKS_IDX -aak_block_unset \
        AK_PKG_TO_IDX_PAIR_MAP_IDX -aak_idx_pair_unset \
        --- "${@}"
}

function __akl_split() {
    local l=${1}; shift
    local op_var_name=${1}; shift
    local pkg_var_name=${1}; shift
    local version_var_name=${1}; shift
    local keywords_var_name=${1}; shift

    local operator='' pkg='' ver='' kw=''

    case ${l} in
        '<='*|'>='*)
            operator=${l:0:2}
            l=${l:2}
            ;;
        '<'*|'='*|'~'*|'>'*)
            operator=${l:0:1}
            l=${l:1}
            ;;
    esac
    if [[ ${l} =~ ^([A-Za-z0-9_][A-Za-z0-9+_.-]*/[A-Za-z0-9_][A-Za-z0-9+_]*(-[A-Za-z+_][A-Za-z0-9+_]*)*) ]]; then
        pkg=${BASH_REMATCH[1]}
        l=${l:${#BASH_REMATCH[1]}}
    fi
    if [[ ${l} =~ ^-([0-9][^[:space:]]*) ]]; then
        ver=${BASH_REMATCH[1]}
        l=${l:${#BASH_REMATCH[0]}}
        if [[ ${ver} = *'*' ]]; then
            operator+='*'
            ver=${ver%'*'}
        fi
    fi
    if [[ ${l} =~ ^[[:space:]]*(.*) ]]; then
        kw=${BASH_REMATCH[1]}
    fi
    assign_to_ref "${op_var_name}" "${operator}"
    assign_to_ref "${pkg_var_name}" "${pkg}"
    assign_to_ref "${version_var_name}" "${ver}"
    assign_to_ref "${keywords_var_name}" "${kw}"
}

function accept_keywords_parse() {
    local -n ak_ref=${1}; shift
    local path=${1}; shift
    local -a throw_away_array=()
    local warn_array_name=throw_away_array
    if [[ ${#} -gt 0 ]]; then
        warn_array_name=${1}; shift
    fi
    local -n warn_array_ref=${warn_array_name}

    local akp_blocks_name akp_pkg_to_idx_pair_map_name
    gen_varname akp_blocks_name
    gen_varname akp_pkg_to_idx_pair_map_name
    declare -ga "${akp_blocks_name}=()"
    declare -gA "${akp_pkg_to_idx_pair_map_name}=()"

    local -n blocks_ref=${akp_blocks_name}
    local -n pkg_to_idx_pair_map_ref=${akp_pkg_to_idx_pair_map_name}

    local -a comments_so_far=() pkgs_so_far=()
    local akp_block_comments_var_name akp_block_entries_var_name akp_block_var_name akp_block_entry_var_name
    local akp_op akp_qpkg akp_ver akp_kw akp_idx_pair_var_name
    local l pkg_line create_block
    local -i block_idx=0 entry_idx
    while read -r l; do
        case ${l} in
            '#'*) comments_so_far+=("${l}");;
            '')
                akp_block_comments_var_name='EMPTY_ARRAY'
                akp_block_entries_var_name='EMPTY_ARRAY'
                create_block=''
                if [[ ${#comments_so_far[@]} -gt 0 ]]; then
                    gen_varname akp_block_comments_var_name
                    declare -ga "${akp_block_comments_var_name}=( ${comments_so_far[*]@Q} )"
                    create_block=x
                fi
                if [[ ${#pkgs_so_far[@]} -gt 0 ]]; then
                    gen_varname akp_block_entries_var_name
                    declare -ga "${akp_block_entries_var_name}=()"
                    local -n block_entries_ref=${akp_block_entries_var_name}
                    for pkg_line in "${pkgs_so_far[@]}"; do
                        __akl_split "${pkg_line}" akp_op akp_qpkg akp_ver akp_kw
                        gen_varname akp_block_entry_var_name
                        ak_block_entry_declare "${akp_block_entry_var_name}"
                        assign_struct_members "${akp_block_entry_var_name}" \
                                              AKBE_OP_IDX "${akp_op}" \
                                              AKBE_QPKG_IDX "${akp_qpkg}" \
                                              AKBE_VERSION_IDX "${akp_ver}" \
                                              AKBE_KEYWORDS_IDX "${akp_kw}"
                        block_entries_ref+=( "${akp_block_entry_var_name}" )
                    done
                    unset -n block_entries_ref
                    create_block=x
                fi
                if [[ -n ${create_block} ]]; then
                    gen_varname akp_block_var_name
                    ak_block_declare "${akp_block_var_name}"
                    assign_struct_members "${akp_block_var_name}" \
                                          AKB_COMMENTS_IDX "${akp_block_comments_var_name}" \
                                          AKB_BLOCK_ENTRIES_IDX "${akp_block_entries_var_name}"
                    blocks_ref+=( "${akp_block_var_name}" )
                    entry_idx=0
                    for pkg_line in "${pkgs_so_far[@]}"; do
                        __akl_split "${pkg_line}" akp_op akp_qpkg akp_ver akp_kw
                        if [[ -n ${pkg_to_idx_pair_map_ref["${akp_qpkg}"]:-} ]]; then
                            warn_array_ref+=( "duplicated entry for package ${pkg} in line ${lineno}: ${pkg_line@Q}, ignoring" )
                            continue
                        fi
                        gen_varname akp_idx_pair_var_name
                        ak_idx_pair_declare "${akp_idx_pair_var_name}"
                        assign_struct_members "${akp_idx_pair_var_name}" \
                                              AKIP_BLOCK_IDX_IDX "${block_idx}" \
                                              AKIP_ENTRY_IDX_IDX "${entry_idx}"
                        pkg_to_idx_pair_map_ref["${akp_qpkg}"]=${akp_idx_pair_var_name}
                        ((++entry_idx))
                    done
                    ((++block_idx))
                fi
                comments_so_far=()
                pkgs_so_far=()
                ;;
            *) pkgs_so_far+=( "${l}" );;
        esac
    done < <(cat "${path}"; echo '') # extra newline to dump the last
                                     # entry that is not followed by
                                     # an empty line
    ak_ref[AK_BLOCKS_IDX]=${akp_blocks_name}
    ak_ref[AK_PKG_TO_IDX_PAIR_MAP_IDX]=${akp_pkg_to_idx_pair_map_name}
}

function accept_keywords_add() {
    local ak_var_name=${1}; shift
    local comment=${1}; shift
    local qpkg=${1}; shift
    local version=${1}; shift

    accept_keywords_remove "${ak_var_name}" "${qpkg}"

    local -n ak_ref=${ak_var_name}

    ak_ref[AK_MODIFIED]=x

    if [[ ${ak_ref[AK_PKG_TO_IDX_PAIR_MAP_IDX]} = 'EMPTY_MAP' ]]; then
        local aka_map_name
        gen_varname aka_map_name
        declare -gA "${aka_map_name}=()"
        ak_ref[AK_PKG_TO_IDX_PAIR_MAP_IDX]=${aka_map_name}
        unset aka_map_name
    fi
    if [[ ${ak_ref[AK_BLOCKS_IDX]} = 'EMPTY_ARRAY' ]]; then
        local aka_array_name
        gen_varname aka_array_name
        declare -ga "${aka_array_name}=()"
        ak_ref[AK_BLOCKS_IDX]=${aka_array_name}
        unset aka_array_name
    fi

    local -n pkg_to_idx_pair_map_ref=${ak_ref[AK_PKG_TO_IDX_PAIR_MAP_IDX]}
    local -n blocks_ref=${ak_ref[AK_BLOCKS_IDX]}
    local op=''

    if [[ -n ${version} ]]; then
        op='='
        if [[ ${version} = *'*' ]]; then
            op+='*'
            version=${version%'*'}
        fi
    fi

    # first, a block entry (so an actual accept keywords line)
    local aka_block_entry_var_name
    gen_varname aka_block_entry_var_name
    ak_block_entry_declare "${aka_block_entry_var_name}"
    assign_struct_members "${aka_block_entry_var_name}" \
                          AKBE_OP_IDX "${op}" \
                          AKBE_QPKG_IDX "${qpkg}" \
                          AKBE_VERSION_IDX "${version}" \
                          AKBE_KEYWORDS_IDX '' \
                          AKBE_MARKED_FOR_REMOVAL_IDX ''
    # entries array and comments array
    local aka_block_entries_var_name aka_comments_var_name
    gen_varname aka_block_entries_var_name
    declare -ga "${aka_block_entries_var_name}=( ${aka_block_entry_var_name@Q} )"
    gen_varname aka_comments_var_name
    declare -ga "${aka_comments_var_name}=( ${comment@Q} )"
    # the block
    local aka_block_var_name
    gen_varname aka_block_var_name
    ak_block_declare "${aka_block_var_name}"
    assign_struct_members "${aka_block_var_name}" \
                          AKB_COMMENTS_IDX "${aka_comments_var_name}" \
                          AKB_BLOCK_ENTRIES_IDX "${aka_block_entries_var_name}"
    local -i block_idx=${#blocks_ref[@]}
    blocks_ref+=( "${aka_block_var_name}" )
    # pair idx
    local aka_idx_pair_var_name
    gen_varname aka_idx_pair_var_name
    ak_idx_pair_declare "${aka_idx_pair_var_name}"
    assign_struct_members "${aka_idx_pair_var_name}" \
                          AKIP_BLOCK_IDX_IDX ${block_idx} \
                          AKIP_ENTRY_IDX_IDX 0
    pkg_to_idx_pair_map_ref["${qpkg}"]=${aka_idx_pair_var_name}
}

function accept_keywords_get() {
    local -n ak_ref=${1}; shift
    local qpkg=${1}; shift
    local entry_var_name_var_name=${1}; shift

    local -n pkg_to_idx_pair_map_ref=${ak_ref[AK_PKG_TO_IDX_PAIR_MAP_IDX]}
    local idx_pair_var_name=${pkg_to_idx_pair_map_ref["${qpkg}"]:-}
    local entry_var_name=''

    if [[ -n ${idx_pair_var_name} ]]; then
        local -i akg_block_idx akg_entry_idx
        get_struct_members "${idx_pair_var_name}" \
                           AKIP_BLOCK_IDX_IDX akg_block_idx \
                           AKIP_ENTRY_IDX_IDX akg_entry_idx
        local -n blocks_ref=${ak_ref[AK_BLOCKS_IDX]}
        local block_var_name=${blocks_ref[akg_block_idx]}
        unset -n blocks_ref
        local akg_entries_name akg_marked
        get_struct_members "${block_var_name}" \
                           AKB_BLOCK_ENTRIES_IDX akg_entries_name \
                           AKB_MARKED_FOR_REMOVAL_IDX akg_marked
        if [[ -z ${akg_marked} ]]; then
            local -n entries_ref=${akg_entries_name}
            entry_var_name=${entries_ref[akg_entry_idx]}
            unset -n entries_ref
            get_struct_members "${entry_var_name}" \
                               AKBE_MARKED_FOR_REMOVAL_IDX akg_marked
            if [[ -n ${akg_marked} ]]; then
                entry_var_name=''
            fi
        fi
    fi
    assign_to_ref "${entry_var_name_var_name}" "${entry_var_name}"
}

function accept_keywords_remove() {
    local -n ak_ref=${1}; shift
    local qpkg=${1}; shift

    local -n pkg_to_idx_pair_map_ref=${ak_ref[AK_PKG_TO_IDX_PAIR_MAP_IDX]}
    local idx_pair_var_name=${pkg_to_idx_pair_map_ref["${qpkg}"]:-}
    local entry_var_name=''

    if [[ -z ${idx_pair_var_name} ]]; then
        return 0
    fi

    ak_ref[AK_MODIFIED]=x

    local -i akr_block_idx akr_entry_idx
    get_struct_members "${idx_pair_var_name}" \
                       AKIP_BLOCK_IDX_IDX akr_block_idx \
                       AKIP_ENTRY_IDX_IDX akr_entry_idx
    unset "pkg_to_idx_pair_map_ref[${qpkg}]"
    local -n blocks_ref=${ak_ref[AK_BLOCKS_IDX]}
    local block_var_name=${blocks_ref[akr_block_idx]}
    unset -n blocks_ref
    local akr_entries_name akr_marked
    get_struct_members "${block_var_name}" \
                       AKB_BLOCK_ENTRIES_IDX akr_entries_name \
                       AKB_MARKED_FOR_REMOVAL_IDX akr_marked
    if [[ -n ${akr_marked} ]]; then
        return 0
    fi
    local -n entries_ref=${akr_entries_name}
    local entry_var_name=${entries_ref[akr_entry_idx]}
    assign_struct_members "${entry_var_name}" \
                          AKBE_MARKED_FOR_REMOVAL_IDX x
    local block_ok=''
    for entry_var_name in "${entries_ref[@]}"; do
        get_struct_members "${entry_var_name}" \
                           AKBE_MARKED_FOR_REMOVAL_IDX akr_marked
        if [[ -z ${akr_marked} ]]; then
            block_ok=x
            break
        fi
    done
    unset -n entries_ref
    if [[ -z ${block_ok} ]]; then
        assign_struct_members "${block_var_name}" \
                              AKB_MARKED_FOR_REMOVAL_IDX x
    fi
}

function accept_keywords_mark_as_modified() {
    local -n ak_ref=${1}; shift

    ak_ref[AK_MODIFIED]=x
}

function accept_keywords_is_modified() {
    local -n ak_ref=${1}; shift

    [[ -n ${ak_ref[AK_MODIFIED]} ]]
}

function accept_keywords_write() {
    local -n ak_ref=${1}; shift
    local path=${1}; shift

    local -n blocks_ref=${ak_ref[AK_BLOCKS_IDX]}
    local -n pkg_to_idx_pair_map_ref=${ak_ref[AK_PKG_TO_IDX_PAIR_MAP_IDX]}
    local precede_with_empty_line=''

    # first, write the header comments (blocks with comments only, no packages)
    local block_name akw_marked_for_removal akw_comments_name akw_entries_name
    local -i akw_entries_count
    for block_name in "${blocks_ref[@]}"; do
        get_struct_members "${block_name}" \
                           AKB_MARKED_FOR_REMOVAL_IDX akw_marked_for_removal \
                           AKB_COMMENTS_IDX akw_comments_name \
                           AKB_BLOCK_ENTRIES_IDX akw_entries_name
        if [[ -n ${akw_marked_for_removal} ]]; then
            continue
        fi
        array_ref_len "${akw_entries_name}" akw_entries_count
        if [[ akw_entries_count -gt 0 ]]; then
            break
        fi
        local -n comments_ref=${akw_comments_name}
        if [[ ${#comments_ref[@]} -gt 0 ]]; then
            if [[ -n ${precede_with_empty_line} ]]; then
                echo ''
            else
                precede_with_empty_line=x
            fi
            printf '%s\n' "${comments_ref[@]}"
        fi
        unset -n comments_ref
    done >"${path}"

    if [[ ${#pkg_to_idx_pair_map_ref[@]} -eq 0 ]]; then
        return 0
    fi

    local -a sorted_packages
    mapfile -t sorted_packages < <(printf '%s\n' "${!pkg_to_idx_pair_map_ref[@]}" | csort -u)

    local -a current_comments=( 'impossibru comment without a starting hash' )
    local same_comments
    local qpkg idx_pair_name akw_entry_name
    local -i akw_block_idx akw_entry_idx comment_idx
    local akw_op akw_version akw_keywords pkg_line
    for qpkg in "${sorted_packages[@]}"; do
        idx_pair_name=${pkg_to_idx_pair_map_ref["${qpkg}"]}
        get_struct_members "${idx_pair_name}" \
                           AKIP_BLOCK_IDX_IDX akw_block_idx \
                           AKIP_ENTRY_IDX_IDX akw_entry_idx
        block_name=${blocks_ref[akw_block_idx]}
        get_struct_members "${block_name}" \
                           AKB_MARKED_FOR_REMOVAL_IDX akw_marked_for_removal \
                           AKB_COMMENTS_IDX akw_comments_name \
                           AKB_BLOCK_ENTRIES_IDX akw_entries_name
        if [[ -n ${akw_marked_for_removal} ]]; then
            fail "inconsistent marking for removal - the package ${qpkg} should not be in pkg to idx pair map, because the block it points to is marked for removal"
        fi
        array_ref_get "${akw_entries_name}" "${akw_entry_idx}" akw_entry_name
        get_struct_members "${akw_entry_name}" \
                           AKBE_OP_IDX akw_op \
                           AKBE_VERSION_IDX akw_version \
                           AKBE_KEYWORDS_IDX akw_keywords \
                           AKBE_MARKED_FOR_REMOVAL_IDX akw_marked_for_removal
        if [[ -n ${akw_marked_for_removal} ]]; then
            fail "inconsistent marking for removal - the package ${qpkg} should not be in pkg to idx pair map, because the entry it points to is marked for removal"
        fi
        local -n block_comments_ref=${akw_comments_name}
        if [[ ${#block_comments_ref[@]} -eq ${#current_comments[@]} ]]; then
            same_comments=x
            for ((comment_idx = 0; comment_idx < ${#current_comments[@]}; ++comment_idx)); do
                if [[ ${block_comments_ref[comment_idx]} != "${current_comments[comment_idx]}" ]]; then
                    same_comments=''
                    break
                fi
            done
        else
            same_comments=''
        fi
        if [[ -z ${same_comments} ]]; then
            current_comments=( "${block_comments_ref[@]}" )
            if [[ -n ${precede_with_empty_line} ]]; then
                echo ''
            else
                precede_with_empty_line=x
            fi
            printf '%s\n' "${block_comments_ref[@]}"
        fi
        unset -n block_comments_ref
        if [[ ${akw_op} = '=*' ]]; then
            akw_op='='
            akw_version+='*'
        fi
        if [[ -n ${akw_op} && -n ${akw_version} ]]; then
            pkg_line="${akw_op}${qpkg}-${akw_version}"
        else
            pkg_line=${qpkg}
        fi
        if [[ -n ${akw_keywords} ]]; then
            pkg_line+=" ${akw_keywords}"
        fi
        echo "${pkg_line}"
    done >>"${path}"
}

fi
