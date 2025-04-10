#!/bin/bash

# This file implements parsing the md5-metadata cache files and
# accessing the parsed results. Not the entirety of the cache file is
# parsed, only the parts that were needed at the time of writing
# it. So currently the exposed parts of parsed cache files are EAPI,
# IUSE, KEYWORDS, LICENSE, {B,R,P,I,}DEPEND and _eclasses_. The
# _eclasses_ part discards the checksums, though, so only names are
# available.

if [[ -z ${__MD5_CACHE_LIB_SH_INCLUDED__:-} ]]; then
__MD5_CACHE_LIB_SH_INCLUDED__=x

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"
source "${PKG_AUTO_IMPL_DIR}/debug.sh"
source "${PKG_AUTO_IMPL_DIR}/gentoo_ver.sh"

#
# Cache file
#

# Indices to access fields of the cache file:
# PCF_EAPI_IDX     - a string/number describing EAPI
# PCF_KEYWORDS_IDX - a name of an array containing keyword objects
# PCF_IUSE_IDX     - a name of an array containing iuse objects
# PCF_BDEPEND_IDX  - a name of a group object with build dependencies
# PCF_DEPEND_IDX   - a name of a group object with dependencies
# PCF_IDEPEND_IDX  - a name of a group object with install dependencies
# PCF_PDEPEND_IDX  - a name of a group object with post dependencies
# PCF_RDEPEND_IDX  - a name of a group object with runtime dependencies
# PCF_LICENSE_IDX  - a name of a group object with licenses
# PCF_ECLASSES_IDX - a name of an array with used eclasses
declare -gri PCF_EAPI_IDX=0 PCF_KEYWORDS_IDX=1 PCF_IUSE_IDX=2 PCF_BDEPEND_IDX=3 PCF_DEPEND_IDX=4 PCF_IDEPEND_IDX=5 PCF_PDEPEND_IDX=6 PCF_RDEPEND_IDX=7 PCF_LICENSE_IDX=8 PCF_ECLASSES_IDX=9

# Declares empty cache files. Can take flags that are passed to
# declare. Usually only -r or -t make sense to pass. Can take several
# names, just like declare. Takes no initializers - this is hardcoded.
function cache_file_declare() {
    struct_declare -ga "${@}" "( '0' 'EMPTY_ARRAY' 'EMPTY_ARRAY' 'EMPTY_GROUP' 'EMPTY_GROUP' 'EMPTY_GROUP' 'EMPTY_GROUP' 'EMPTY_GROUP' 'EMPTY_GROUP' 'EMPTY_ARRAY' )"
}

# Unsets cache files, can take several names, just like unset.
function cache_file_unset() {
    local name
    for name; do
        local -n cache_file_ref=${name}

        __mcl_unset_array "${cache_file_ref[PCF_KEYWORDS_IDX]}" kw_unset
        __mcl_unset_array "${cache_file_ref[PCF_IUSE_IDX]}" iuse_unset
        __mcl_unset_array "${cache_file_ref[PCF_ECLASSES_IDX]}" unset

        group_unset \
            "${cache_file_ref[PCF_BDEPEND_IDX]}" \
            "${cache_file_ref[PCF_DEPEND_IDX]}" \
            "${cache_file_ref[PCF_IDEPEND_IDX]}" \
            "${cache_file_ref[PCF_PDEPEND_IDX]}" \
            "${cache_file_ref[PCF_RDEPEND_IDX]}" \
            "${cache_file_ref[PCF_LICENSE_IDX]}"

        unset -n cache_file_ref
    done
    unset "${@}"
}

# Parses a cache file under the passed path.
#
# Params:
#
# 1 - cache file
# 2 - path to the cache file
function parse_cache_file() {
    local -n cache_file_ref=${1}; shift
    local path=${1}; shift
    # rest are architectures

    if pkg_debug_enabled; then
        local -a file_lines
        mapfile -t file_lines <"${path}"
        pkg_debug_print_lines "parsing ${path@Q}" "${file_lines[@]}"
        unset file_lines
    fi

    local -n pkg_eapi_ref='cache_file_ref[PCF_EAPI_IDX]'
    local -n pkg_keywords_ref='cache_file_ref[PCF_KEYWORDS_IDX]'
    local -n pkg_iuse_ref='cache_file_ref[PCF_IUSE_IDX]'
    local -n pkg_bdepend_group_name_ref='cache_file_ref[PCF_BDEPEND_IDX]'
    local -n pkg_depend_group_name_ref='cache_file_ref[PCF_DEPEND_IDX]'
    local -n pkg_idepend_group_name_ref='cache_file_ref[PCF_IDEPEND_IDX]'
    local -n pkg_pdepend_group_name_ref='cache_file_ref[PCF_PDEPEND_IDX]'
    local -n pkg_rdepend_group_name_ref='cache_file_ref[PCF_RDEPEND_IDX]'
    local -n pkg_license_group_name_ref='cache_file_ref[PCF_LICENSE_IDX]'
    local -n pkg_eclasses_ref='cache_file_ref[PCF_ECLASSES_IDX]'

    local l key
    while read -r l; do
        key=${l%%=*}
        pkg_debug "parsing ${key@Q}"
        case ${key} in
            'EAPI')
                pkg_eapi_ref=${l#*=}
                pkg_debug "EAPI: ${pkg_eapi_ref}"
                ;;
            'KEYWORDS')
                __mcl_parse_keywords "${l#*=}" pkg_keywords_ref "${@}"
                ;;
            'IUSE')
                __mcl_parse_iuse "${l#*=}" pkg_iuse_ref
                ;;
            'BDEPEND')
                __mcl_parse_dsf "${__MCL_DSF_DEPEND}" "${l#*=}" pkg_bdepend_group_name_ref
                ;;
            'DEPEND')
                __mcl_parse_dsf "${__MCL_DSF_DEPEND}" "${l#*=}" pkg_depend_group_name_ref
                ;;
            'IDEPEND')
                __mcl_parse_dsf "${__MCL_DSF_DEPEND}" "${l#*=}" pkg_idepend_group_name_ref
                ;;
            'PDEPEND')
                __mcl_parse_dsf "${__MCL_DSF_DEPEND}" "${l#*=}" pkg_pdepend_group_name_ref
                ;;
            'RDEPEND')
                __mcl_parse_dsf "${__MCL_DSF_DEPEND}" "${l#*=}" pkg_rdepend_group_name_ref
                ;;
            'LICENSE')
                __mcl_parse_dsf "${__MCL_DSF_LICENSE}" "${l#*=}" pkg_license_group_name_ref
                ;;
            '_eclasses_')
                __mcl_parse_eclasses "${l#*=}" pkg_eclasses_ref
                ;;
            *)
                pkg_debug "Not parsing ${key@Q}, ignoring"
                ;;
        esac
    done <"${path}"
}

#
# Use requirement (the part in the square brackets in the package
# dependency specification).
#

# Indices to access fields of the use requirement:
# UR_NAME_IDX    - a use name
# UR_MODE_IDX    - a string describing the mode: "+" is enabled, "="
#                  is strict relation, "!=" reversed strict relation,
#                  "?"  is "enabled if enabled in the ebuild", "!?" is
#                  "disabled if disabled in the ebuild", and "-" is
#                  disabled)
# UR_PRETEND_IDX - a string describing pretend mode: it can be either
#                  empty (no pretending if use is missing in the
#                  package), "+" (pretend enabled if missing in the
#                  package), or "-" (pretend disabled if missing in
#                  the package)
declare -gri UR_NAME_IDX=0 UR_MODE_IDX=1 UR_PRETEND_IDX=2

# Declares empty use requirements. Can take flags that are passed to
# declare. Usually only -r or -t make sense to pass. Can take several
# names, just like declare. Takes no initializers - this is hardcoded.
function ur_declare() {
    struct_declare -ga "${@}" "( 'ITS_UNSET' '+' '' )"
}

# Unsets use requirements, can take several names, just like unset.
function ur_unset() {
    unset "${@}"
}

# Copies use requirement into another.
#
# Params:
#
# 1 - use requirement to be clobbered
# 2 - the source use requirement
function ur_copy() {
    local -n to_clobber_ref=${1}; shift
    local -n to_copy_ref=${1}; shift

    local -i idx
    for idx in UR_NAME_IDX UR_MODE_IDX UR_PRETEND_IDX; do
        to_clobber_ref[idx]=${to_copy_ref[idx]}
    done
}

# Stringifies use requirement.
#
# Params:
#
# 1 - use requirement
# 2 - name of a variable where the string form will be stored
function ur_to_string() {
    local -n ur_ref=${1}; shift
    local -n str_ref=${1}; shift

    case ${ur_ref[UR_MODE_IDX]} in
        '!'*)
            str_ref='!'
            ;;
        '-'*)
            str_ref='-'
            ;;
        *)
            str_ref=''
            ;;
    esac
    str_ref+=${ur_ref[UR_NAME_IDX]}

    local p=${ur_ref[UR_PRETEND_IDX]}
    if [[ -n ${p} ]]; then
        str_ref+="(${p})"
    fi
    case ${ur_ref[UR_MODE_IDX]} in
        *'=')
            str_ref+='='
            ;;
        *'?')
            str_ref+='?'
            ;;
    esac
}

#
# Package depedency specification (or PDS)
#

# Enumeration describing blocker mode of a package. Self-describing.
declare -gri PDS_NO_BLOCK=0 PDS_WEAK_BLOCK=1 PDS_STRONG_BLOCK=2

# Indices to access fields of the package dependency specification:
# PDS_BLOCKS_IDX - a number describing blocker mode (use PDS_NO_BLOCK,
#                  PDS_WEAK_BLOCK and PDS_STRONG_BLOCK)
# PDS_OP_IDX     - a string describing the relational operator, can be
#                  empty or one of "<", "<=", "=", "=*", "~", ">=", or
#                  ">" ("=*" is same as "=" with asterisk appended to
#                  version)
#                  if empty, the version will also be empty
# PDS_NAME_IDX   - a qualified package name (so category/name)
# PDS_VER_IDX    - a version of the package, may be empty (if so,
#                  operator is also empty)
# PDS_SLOT_IDX   - a string describing the slot operator, without the
#                  preceding colon
# PDS_UR_IDX     - a name of an array variable containing use
#                  requirements
declare -gri PDS_BLOCKS_IDX=0 PDS_OP_IDX=1 PDS_NAME_IDX=2 PDS_VER_IDX=3 PDS_SLOT_IDX=4 PDS_UR_IDX=5

# Declares empty package definition specifications. Can take flags
# that are passed to declare. Usually only -r or -t make sense to
# pass. Can take several names, just like declare. Takes no
# initializers - this is hardcoded.
function pds_declare() {
    struct_declare -ga "${@}" "( ${PDS_NO_BLOCK@Q} '' 'ITS_UNSET' '' '' 'EMPTY_ARRAY' )"
}

# Unsets package definition specifications, can take several names,
# just like unset.
function pds_unset() {
    local use_reqs_name name
    for name; do
        local -n pds_ref=${name}

        use_reqs_name=${pds_ref[PDS_UR_IDX]}
        local -n use_reqs_ref=${use_reqs_name}
        ur_unset "${use_reqs_ref[@]}"
        unset -n use_reqs_ref
        if [[ ${use_reqs_name} != 'EMPTY_ARRAY' ]]; then
            unset "${use_reqs_name}"
        fi

        unset -n pds_ref
    done
    unset "${@}"
}

# Copies package dependency specification into another.
#
# Params:
#
# 1 - package dependency specification to be clobbered
# 2 - the source package dependency specification
function pds_copy() {
    local -n to_clobber_ref=${1}; shift
    local -n to_copy_ref=${1}; shift

    local -i idx
    for idx in PDS_BLOCKS_IDX PDS_OP_IDX PDS_NAME_IDX PDS_VER_IDX PDS_SLOT_IDX; do
        to_clobber_ref[idx]=${to_copy_ref[idx]}
    done

    if [[ ${to_copy_ref[PDS_UR_IDX]} = 'EMPTY_ARRAY' || ${#to_copy_ref[PDS_UR_IDX]} -eq 0 ]]; then
        to_clobber_ref[PDS_UR_IDX]='EMPTY_ARRAY'
    else
        local pc_ur_array_name
        gen_varname pc_ur_array_name
        declare -ga "${pc_ur_array_name}=()"

        local -n urs_to_copy_ref=${to_copy_ref[PDS_UR_IDX]} urs_ref=${pc_ur_array_name}
        local ur_name pc_ur_name
        for ur_name in "${urs_to_copy_ref[@]}"; do
            gen_varname pc_ur_name
            ur_declare "${pc_ur_name}"
            ur_copy "${pc_ur_name}" "${ur_name}"
            urs_ref+=( "${pc_ur_name}" )
        done

        to_clobber_ref[PDS_UR_IDX]=${pc_ur_array_name}
    fi
}

# Adds use requirements to the package dependency specification.
#
# Params:
#
# 1 - package dependency specification
# @ - use requirements
function pds_add_urs() {
    local -n pds_ref=${1}; shift
    # rest are use requirements

    if [[ ${#} -eq 0 ]]; then
        return 0
    fi

    local use_reqs_name=${pds_ref[PDS_UR_IDX]}
    if [[ ${use_reqs_name} = 'EMPTY_ARRAY' ]]; then
        local ura_name
        gen_varname ura_name
        declare -ga "${ura_name}=()"
        pds_ref[PDS_UR_IDX]=${ura_name}
        use_reqs_name=${ura_name}
        unset ura_name
    fi

    local -n use_reqs_ref=${use_reqs_name}
    use_reqs_ref+=( "${@}" )
}

# Stringifies package dependency specification.
#
# Params:
#
# 1 - package dependency specification
# 2 - name of a variable where the string form will be stored
function pds_to_string() {
    local -n pds_ref=${1}; shift
    local -n str_ref=${1}; shift

    case ${pds_ref[PDS_BLOCKS_IDX]} in
        "${PDS_NO_BLOCK}")
            str_ref=''
            ;;
        "${PDS_WEAK_BLOCK}")
            str_ref='!'
            ;;
        "${PDS_STRONG_BLOCK}")
            str_ref='!!'
            ;;
    esac
    local op=${pds_ref[PDS_OP_IDX]}
    local v=${pds_ref[PDS_VER_IDX]}
    if [[ ${op} = '=*' ]]; then
        op='='
        # if there's an op, then we assume version is not empty - so
        # version will never end up being just *
        v+='*'
    fi
    str_ref+=${op}${pds_ref[PDS_NAME_IDX]}
    if [[ -n ${v} ]]; then
        str_ref+=-${v}
    fi
    local s=${pds_ref[PDS_SLOT_IDX]}
    if [[ -n ${s} ]]; then
        str_ref+=:${s}
    fi
    local -n urs_ref=${pds_ref[PDS_UR_IDX]}
    if [[ ${#urs_ref[@]} -gt 0 ]]; then
        str_ref+='['
        local u ur_str
        for u in "${urs_ref[@]}"; do
            ur_to_string "${u}" ur_str
            str_ref+=${ur_str},
        done
        unset ur_str u
        str_ref=${str_ref:0:$(( ${#str_ref} - 1 ))}']'
    fi
}

#
# Group. A structure for describing {B,R,I,P,}DEPEND and LICENSE
# fields. Contains items, which can be either package dependency
# specifications or another groups. So it is a recursive structure.
#

# Enumeration describing type of a group. Self-describing.
declare -gri GROUP_ALL_OF=0 GROUP_ANY_OF=1

# Enumeration describing whether items in group are for enabled or disabled USE. Self-describing.
declare -gri GROUP_USE_ENABLED=0 GROUP_USE_DISABLED=1

# Indices to access fields of the group:
# GROUP_TYPE_IDX    - a number describing a type of the group (use
#                     GROUP_ALL_OF and GROUP_ANY_OF)
# GROUP_USE_IDX     - a USE name of the group, may be empty, and must
#                     be empty for GROUP_ANY_OF groups
# GROUP_ENABLED_IDX - a number describing mode of the USE, should be
#                     ignored if USE name is empty (use
#                     GROUP_USE_ENABLED and GROUP_USE_DISABLED)
# GROUP_ITEMS_IDX   - a name of an array containing items
declare -gri GROUP_TYPE_IDX=0 GROUP_USE_IDX=1 GROUP_ENABLED_IDX=2 GROUP_ITEMS_IDX=3

# Declares empty groups. Can take flags that are passed to
# declare. Usually only -r or -t make sense to pass. Can take several
# names, just like declare. Takes no initializers - this is hardcoded.
function group_declare() {
    struct_declare -ga "${@}" "( ${GROUP_ALL_OF@Q} '' ${GROUP_USE_ENABLED@Q} 'EMPTY_ARRAY' )"
}

# An empty readonly group.
group_declare -r EMPTY_GROUP

# Unsets groups, can take several names, just like unset.
function group_unset() {
    local -a to_unset=()
    local name items_name
    for name; do
        if [[ ${name} == 'EMPTY_GROUP' ]]; then
            continue
        fi

        local -n group_ref=${name}
        items_name=${group_ref[GROUP_ITEMS_IDX]}
        unset -n group_ref

        to_unset+=( "${name}" )
        if [[ ${items_name} == 'EMPTY_ARRAY' ]]; then
            continue
        fi
        to_unset+=( "${items_name}" )

        local -n items_ref=${items_name}
        item_unset "${items_ref[@]}"
        unset -n items_ref
    done
    unset "${to_unset[@]}"
}

# Copies group into another.
#
# Params:
#
# 1 - group to be clobbered
# 2 - the source group
function group_copy() {
    local -n to_clobber_ref=${1}; shift
    local -n to_copy_ref=${1}; shift

    local -i idx
    for idx in GROUP_TYPE_IDX GROUP_USE_IDX GROUP_ENABLED_IDX; do
        to_clobber_ref[idx]=${to_copy_ref[idx]}
    done

    if [[ ${to_copy_ref[GROUP_ITEMS_IDX]} = 'EMPTY_ARRAY' || ${#to_copy_ref[GROUP_ITEMS_IDX]} -eq 0 ]]; then
        to_clobber_ref[GROUP_ITEMS_IDX]='EMPTY_ARRAY'
    else
        local gc_items_name
        gen_varname gc_items_name
        declare -ga "${gc_items_name}=()"

        local -n items_to_copy_ref=${to_copy_ref[GROUP_ITEMS_IDX]}
        local -n items_ref=${gc_items_name}
        local item_name_to_copy gc_item_name
        for item_name_to_copy in "${items_to_copy_ref[@]}"; do
            gen_varname gc_item_name
            item_declare "${gc_item_name}"
            item_copy "${gc_item_name}" "${item_name_to_copy}"
            items_ref+=( "${gc_item_name}" )
        done
        unset -n items_ref items_to_copy_ref
        to_clobber_ref[GROUP_ITEMS_IDX]="${gc_items_name}"
    fi
}

# Adds items to the group.
#
# Params:
#
# 1 - group
# @ - items
function group_add_items() {
    local -n group_ref=${1}; shift
    # rest are items to add

    if [[ ${#} -eq 0 ]]; then
        return 0
    fi

    local items_name=${group_ref[GROUP_ITEMS_IDX]}
    if [[ ${items_name} = 'EMPTY_ARRAY' ]]; then
        local ia_name
        gen_varname ia_name
        declare -ga "${ia_name}=()"
        group_ref[GROUP_ITEMS_IDX]=${ia_name}
        items_name=${ia_name}
        unset ia_name
    fi

    local -n items_ref=${items_name}
    items_ref+=( "${@}" )
}

# Stringifies group.
#
# Params:
#
# 1 - group
# 2 - name of a variable where the string form will be stored
function group_to_string() {
    local -n group_ref=${1}; shift
    local -n str_ref=${1}; shift

    local t=${group_ref[GROUP_TYPE_IDX]}
    case ${t} in
        "${GROUP_ALL_OF}")
            local u=${group_ref[GROUP_USE_IDX]}
            if [[ -n ${u} ]]; then
                local e=${group_ref[GROUP_ENABLED_IDX]}
                case ${e} in
                    "${GROUP_USE_ENABLED}")
                        str_ref=''
                        ;;
                    "${GROUP_USE_DISABLED}")
                        str_ref='!'
                esac
                unset e
                str_ref+="${u}? "
            else
                str_ref=''
            fi
            unset u
            ;;
        "${GROUP_ANY_OF}")
            str_ref='|| '
            ;;
    esac

    str_ref+='( '
    local -n item_names_ref=${group_ref[GROUP_ITEMS_IDX]}
    if [[ ${#item_names_ref[@]} -gt 0 ]]; then
        local item_name item_str
        for item_name in "${item_names_ref[@]}"; do
            item_to_string "${item_name}" item_str
            str_ref+="${item_str} "
        done
        unset item_str item_name
    fi
    str_ref+=')'
}

#
# Item. A string of <mode>:<data>. Mode is a single char and describes
# the data.
#
# Modes:
# "e" - empty, data is meaningless and should be just empty.
# "g" - group, data is a group (a name of a variable containing a
#       group)
# "l" - license, data is a name of a license (plain string)
# "p" - package dependency specification, data is pds (a name of a
#       variable containing a pds)

# Declares empty items. Can take flags that are passed to
# declare. Usually only -r or -t make sense to pass. Can take several
# names, just like declare. Takes no initializers - this is hardcoded.
function item_declare() {
    struct_declare -g "${@}" 'e:'
}

# Unsets items, can take several names, just like unset.
function item_unset() {
    local name
    for name; do
        local -n item_ref=${name}

        case ${item_ref} in
            e:*)
                # noop
                :
                ;;
            g:*)
                group_unset "${item_ref:2}"
                ;;
            l:*)
                # noop, license is just a string
                ;;
            p:*)
                pds_unset "${item_ref:2}"
                ;;
        esac
        unset -n item_ref
    done

    unset "${@}"
}

# Copies item into another.
#
# Params:
#
# 1 - item to be clobbered
# 2 - the source item
function item_copy() {
    local -n to_clobber_ref=${1}; shift
    local -n to_copy_ref=${1}; shift

    local ic_name
    local t=${to_copy_ref:0:1} v=${to_copy_ref:2}
    case ${t} in
        'e'|'l')
            to_clobber_ref=${to_copy_ref}
            ;;
        'g')
            gen_varname ic_name
            group_declare "${ic_name}"
            group_copy "${ic_name}" "${v}"
            to_clobber_ref="g:${ic_name}"
            ;;
        'p')
            gen_varname ic_name
            pds_declare "${ic_name}"
            pds_copy "${ic_name}" "${v}"
            to_clobber_ref="p:${ic_name}"
            ;;
    esac
}

# Stringifies item.
#
# Params:
#
# 1 - item
# 2 - name of a variable where the string form will be stored
function item_to_string() {
    local -n item_ref=${1}; shift
    local -n str_ref=${1}; shift

    local t=${item_ref:0:1}
    case ${t} in
        e)
            str_ref=''
            ;;
        g)
            local group_name=${item_ref:2}
            local group_str
            group_to_string "${group_name}" group_str
            str_ref=${group_str}
            unset group_str group_name
            ;;
        l)
            str_ref=${item_ref:2}
            ;;
        p)
            local pds_name=${item_ref:2}
            local pds_str=''
            pds_to_string "${pds_name}" pds_str
            str_ref=${pds_str}
            unset pds_str pds_name
            ;;
    esac
}

#
# Keyword
#
# n - name of keyword
# m - stable (amd64), unstable (~amd64), broken (-amd64), unknown (absent in KEYWORDS)

# Enumeration describing mode of the keyword.
# KW_STABLE   - like "amd64"
# KW_UNSTABLE - like "~amd64"
# KW_BROKEN   - like "-amd64"
# KW_UNKNOWN  - missing from KEYWORDS entirely
declare -gri KW_STABLE=0 KW_UNSTABLE=1 KW_BROKEN=2 KW_UNKNOWN=3

# Indices to access fields of the keyword:
# KW_NAME_IDX  - name of the architecture
# KW_LEVEL_IDX - mode of the keyword (use KW_STABLE, KW_UNSTABLE,
#                KW_BROKEN and KW_UNKNOWN)
declare -gri KW_NAME_IDX=0 KW_LEVEL_IDX=1

# Declares empty keywords. Can take flags that are passed to
# declare. Usually only -r or -t make sense to pass. Can take several
# names, just like declare. Takes no initializers - this is hardcoded.
function kw_declare() {
    struct_declare -ga "${@}" "( 'ITS_UNSET' ${KW_UNSTABLE@Q} )"
}

# Unsets keywords, can take several names, just like unset.
function kw_unset() {
    unset "${@}"
}

# Stringifies keyword.
#
# Params:
#
# 1 - keyword
# 2 - name of a variable where the string form will be stored
function kw_to_string() {
    local -n kw_ref=${1}; shift
    local -n str_ref=${1}; shift

    local n=${kw_ref[KW_NAME_IDX]}
    case ${kw_ref[KW_LEVEL_IDX]} in
        "${KW_STABLE}")
            str_ref=${n}
            ;;
        "${KW_UNSTABLE}")
            str_ref="~${n}"
            ;;
        "${KW_BROKEN}")
            str_ref="-${n}"
            ;;
        "${KW_UNKNOWN}")
            str_ref=''
            ;;
    esac
}

#
# IUSE
#

# n - name of IUSE flag
# m - 0 or 1 (0 disabled, 1 enabled)

# Enumeration describing mode of the IUSE. Self-describing.
declare -gri IUSE_DISABLED=0 IUSE_ENABLED=1

# Indices to access fields of the IUSE:
# IUSE_NAME_IDX - IUSE name
# IUSE_MODE_IDX - IUSE mode (use IUSE_DISABLED and IUSE_ENABLED)
declare -gri IUSE_NAME_IDX=0 IUSE_MODE_IDX=1

# Declares empty IUSEs. Can take flags that are passed to
# declare. Usually only -r or -t make sense to pass. Can take several
# names, just like declare. Takes no initializers - this is hardcoded.
function iuse_declare() {
    struct_declare -ga "${@}" "( 'ITS_UNSET' ${IUSE_DISABLED@Q} )"
}

# Unsets IUSEs, can take several names, just like unset.
function iuse_unset() {
    unset "${@}"
}

# Stringifies IUSE.
#
# Params:
#
# 1 - IUSE
# 2 - name of a variable where the string form will be stored
function iuse_to_string() {
    local -n iuse_ref=${1}; shift
    local -n str_ref=${1}; shift

    case ${iuse_ref[IUSE_MODE_IDX]} in
        "${IUSE_ENABLED}")
            str_ref='+'
            ;;
        "${IUSE_DISABLED}")
            str_ref=''
            ;;
    esac
    str_ref+=${iuse_ref[IUSE_NAME_IDX]}
}

#
# Implementation details
#

# parse dependency specification format (DSF)

declare -gri __MCL_DSF_DEPEND=0 __MCL_DSF_LICENSE=1

function __mcl_parse_dsf() {
    local -i dsf_type=${1}; shift
    local dep=${1}; shift
    local -n top_group_out_var_name_ref=${1}; shift

    local -a group_stack
    local pd_group pd_item pd_group_created='' pd_pds

    gen_varname pd_group
    group_declare "${pd_group}"
    group_stack+=( "${pd_group}" )

    local -a tokens
    mapfile -t tokens <<<"${dep// /$'\n'}"
    local -i last_index

    local token
    for token in "${tokens[@]}"; do
        if [[ ${token} = '||' ]]; then
            # "any of" group, so create the group, make it an item, add
            # to current group and mark the new group as current
            gen_varname pd_group
            group_declare "${pd_group}"
            local -n g_ref=${pd_group}
            g_ref[GROUP_TYPE_IDX]=${GROUP_ANY_OF}
            unset -n g_ref

            gen_varname pd_item
            item_declare "${pd_item}"
            local -n i_ref=${pd_item}
            i_ref="g:${pd_group}"
            unset -n i_ref

            group_add_items "${group_stack[-1]}" "${pd_item}"

            group_stack+=( "${pd_group}" )
            pd_group_created=x
        elif [[ ${token} =~ ^!?[A-Za-z0-9][A-Za-z0-9+_-]*\?$ ]]; then
            # "use" group, so create the group, make it an item, add
            # to current group and mark the new group as current
            local -i disabled=GROUP_USE_ENABLED
            local use=${token%?}

            if [[ ${use} = '!'* ]]; then
                disabled=GROUP_USE_DISABLED
                use=${use:1}
            fi

            gen_varname pd_group
            group_declare "${pd_group}"
            local -n g_ref=${pd_group}
            g_ref[GROUP_TYPE_IDX]=${GROUP_ALL_OF}
            g_ref[GROUP_USE_IDX]=${use}
            g_ref[GROUP_ENABLED_IDX]=${disabled}
            unset -n g_ref

            unset use disabled

            gen_varname pd_item
            item_declare "${pd_item}"
            local -n i_ref=${pd_item}
            i_ref="g:${pd_group}"
            unset -n i_ref

            group_add_items "${group_stack[-1]}" "${pd_item}"

            group_stack+=( "${pd_group}" )
            pd_group_created=x
        elif [[ ${token} = '(' ]]; then
            # beginning of a group; usually it is already created,
            # because it is an "any of" or "use" group, but it is
            # legal to specify just a "all of" group
            if [[ -n ${pd_group_created} ]]; then
                pd_group_created=
            else
                gen_varname pd_group
                group_declare "${pd_group}"

                gen_varname pd_item
                item_declare "${pd_item}"
                local -n i_ref=${pd_item}
                i_ref="g:${pd_group}"
                unset -n i_ref

                group_add_items "${group_stack[-1]}" "${pd_item}"

                group_stack+=( "${pd_group}" )
            fi
        elif [[ ${token} = ')' ]]; then
            # end of a group, pop it from the stack
            last_index=$(( ${#group_stack[@]} - 1 ))
            unset "group_stack[${last_index}]"
        elif [[ ${token} =~ ^[A-Za-z0-9_][A-Za-z0-9+_.-]*$ ]]; then
            # license
            if [[ dsf_type -ne __MCL_DSF_LICENSE ]]; then
                fail "license tokens are only allowed for LICENSE keys (token: ${token@Q})"
            fi

            gen_varname pd_item
            item_declare "${pd_item}"
            local -n i_ref=${pd_item}
            i_ref="l:${token}"
            unset -n i_ref
            group_add_items "${group_stack[-1]}" "${pd_item}"
        elif [[ ${token} =~ ^!?!?(<|<=|=|~|>=|>)?[A-Za-z0-9_][A-Za-z0-9+_.-]*/[A-Za-z0-9_] ]]; then
            # pds
            if [[ dsf_type -ne __MCL_DSF_DEPEND ]]; then
                fail "package dependency specification is only allowed for DEPEND-like keys (token: ${token@Q})"
            fi

            local -i blocks=PDS_NO_BLOCK
            local operator='' name='' version='' slot=''
            local -a use_requirements=()

            case ${token} in
                '!!'*)
                    blocks=PDS_STRONG_BLOCK
                    token=${token:2}
                    ;;
                '!'*)
                    blocks=PDS_WEAK_BLOCK
                    token=${token:1}
                    ;;
            esac

            case ${token} in
                '<='*|'>='*)
                    operator=${token:0:2}
                    token=${token:2}
                    ;;
                '<'*|'='*|'~'*|'>'*)
                    operator=${token:0:1}
                    token=${token:1}
                    ;;
            esac

            if [[ ${token} = *']' ]]; then
                local use_reqs_string=${token#*'['}
                use_reqs_string=${use_reqs_string%']'}
                token=${token%"[${use_reqs_string}]"}
                local -a use_reqs
                mapfile -t use_reqs <<<"${use_reqs_string//,/$'\n'}"

                unset use_reqs_string

                local ur name mode pretend pd_ur
                for ur in "${use_reqs[@]}"; do
                    name=''
                    mode=''
                    pretend=''
                    case ${ur} in
                        '-'*)
                            mode='-'
                            ur=${ur:1}
                            ;;
                        '!'*)
                            mode='!'
                            ur=${ur:1}
                            ;;
                    esac
                    if [[ ${mode} != '-' ]]; then
                        case ${ur} in
                            *'=')
                                mode+='='
                                ur=${ur%'='}
                                ;;
                            *'?')
                                mode+='?'
                                ur=${ur%'?'}
                                ;;
                        esac
                    fi
                    if [[ -z ${mode} ]]; then
                        mode='+'
                    fi
                    if [[ ${ur} =~ \(([+-])\)$ ]]; then
                        pretend=${BASH_REMATCH[1]}
                        ur=${ur%"(${pretend})"}
                    fi
                    name=${ur}
                    gen_varname pd_ur
                    ur_declare "${pd_ur}"
                    local -n u_ref=${pd_ur}
                    u_ref[UR_NAME_IDX]=${name}
                    u_ref[UR_MODE_IDX]=${mode}
                    u_ref[UR_PRETEND_IDX]=${pretend}
                    unset -n u_ref
                    use_requirements+=( "${pd_ur}" )
                done
                unset pd_ur pretend mode name ur use_reqs
            fi

            if [[ ${token} = *:* ]]; then
                slot=${token#*:}
                token=${token%:"${slot}"}
            fi

            if [[ ${token} = *'*' ]]; then
                operator='=*'
                token=${token%'*'}
            fi
            local ver_ere_with_dash="-(${VER_ERE_UNBOUNDED})$"
            if [[ ${token} =~ ${ver_ere_with_dash} ]]; then
                version=${BASH_REMATCH[1]}
                token=${token%"-${version}"}
            fi
            name=${token}

            gen_varname pd_pds
            pds_declare "${pd_pds}"
            local -n p_ref=${pd_pds}
            p_ref[PDS_BLOCKS_IDX]=${blocks}
            p_ref[PDS_OP_IDX]=${operator}
            p_ref[PDS_NAME_IDX]=${name}
            p_ref[PDS_VER_IDX]=${version}
            p_ref[PDS_SLOT_IDX]=${slot}
            unset -n p_ref
            pds_add_urs "${pd_pds}" "${use_requirements[@]}"
            unset use_requirements slot version name operator blocks

            gen_varname pd_item
            item_declare "${pd_item}"
            local -n i_ref=${pd_item}
            i_ref="p:${pd_pds}"
            unset -n i_ref

            group_add_items "${group_stack[-1]}" "${pd_item}"
        else
            fail "unknown token ${token@Q}"
        fi
    done

    if [[ ${#group_stack[@]} -ne 1 ]]; then
        fail "botched parsing, group stack has ${#group_stack[@]} groups instead of 1"
    fi

    top_group_out_var_name_ref=${group_stack[0]}

    if pkg_debug_enabled; then
        local pd_group_str
        group_to_string "${group_stack[0]}" pd_group_str
        pkg_debug_print "dsf: ${pd_group_str}"
    fi
}

function __mcl_parse_eclasses() {
    local eclasses_string=${1}; shift
    local -n eclasses_out_var_name_ref=${1}; shift

    local eclasses_var_name
    gen_varname eclasses_var_name
    declare -ga "${eclasses_var_name}=()"
    local -n eclasses_ref=${eclasses_var_name}

    local -a tokens
    mapfile -t tokens <<<"${eclasses_string//$'\t'/$'\n'}"

    local token
    local -i eclass_name_now=1
    for token in "${tokens[@]}"; do
        if [[ eclass_name_now -eq 1 ]]; then
            eclasses_ref+=( "${token}" )
        fi
        eclass_name_now=$((eclass_name_now ^ 1))
    done
    eclasses_out_var_name_ref=${eclasses_var_name}

    if pkg_debug_enabled; then
        local joined_eclasses_string
        join_by joined_eclasses_string ' ' "${eclasses_ref[@]}"
        pkg_debug_print "eclasses: ${joined_eclasses_string}"
    fi
}

function __mcl_parse_keywords() {
    local keywords_string=${1}; shift
    local -n keywords_out_var_name_ref=${1}; shift
    # rest are architectures

    local keywords_var_name
    gen_varname keywords_var_name
    declare -ga "${keywords_var_name}=()"
    local -n keywords_ref=${keywords_var_name}

    local -A keywords_set=()

    local -a tokens
    mapfile -t tokens <<<"${keywords_string// /$'\n'}"
    local token
    for token in "${tokens[@]}"; do
        keywords_set["${token}"]=x
    done

    local has_hyphen_star=${keywords_set['-*']:-}
    local arch mark kw_level_pair kw kw_name
    local -i level
    for arch; do
        for kw_level_pair in "${arch}@${KW_STABLE}" "~${arch}@${KW_UNSTABLE}" "-${arch}@${KW_BROKEN}"; do
            kw=${kw_level_pair%@*}
            level=${kw_level_pair#*@}
            mark=${keywords_set["${kw}"]:-}
            if [[ -n ${mark} ]]; then
                gen_varname kw_name
                kw_declare "${kw_name}"
                local -n k_ref=${kw_name}
                k_ref[KW_NAME_IDX]=${arch}
                k_ref[KW_LEVEL_IDX]=${level}
                unset -n k_ref
                keywords_ref+=( "${kw_name}" )
                break
            fi
        done
        if [[ -z ${mark} ]]; then
            gen_varname kw_name
            kw_declare "${kw_name}"
            local -n k_ref=${kw_name}
            k_ref[KW_NAME_IDX]=${arch}
            if [[ -n ${has_hyphen_star} ]]; then
                k_ref[KW_LEVEL_IDX]=${KW_BROKEN}
            else
                k_ref[KW_LEVEL_IDX]=${KW_UNKNOWN}
            fi
            unset -n k_ref
            keywords_ref+=( "${kw_name}" )
        fi
    done
    keywords_out_var_name_ref=${keywords_var_name}

    if pkg_debug_enabled; then
        local -a all_kws_strings=()
        local kw_name pk_kw_str
        local joined_kws_string
        for kw_name in "${keywords_ref[@]}"; do
            kw_to_string "${kw_name}" pk_kw_str
            all_kws_strings+=( "${pk_kw_str}" )
        done
        join_by joined_kws_string ' ' "${all_kws_strings[@]}"
        pkg_debug_print "keywords: ${joined_kws_string}"
    fi
}

function __mcl_parse_iuse() {
    local iuse_string=${1}; shift
    local -n iuse_out_var_name_ref=${1}; shift

    local iuse_var_name
    gen_varname iuse_var_name
    declare -ga "${iuse_var_name}=()"
    local -n iuse_ref=${iuse_var_name}

    local -a tokens
    mapfile -t tokens <<<"${iuse_string// /$'\n'}"
    local token pi_iuse
    for token in "${tokens[@]}"; do
        gen_varname pi_iuse
        iuse_declare "${pi_iuse}"
        local -n i_ref=${pi_iuse}
        if [[ ${token} = '+'* ]]; then
            i_ref[IUSE_MODE_IDX]=${IUSE_ENABLED}
            token=${token:1}
        fi
        i_ref[IUSE_NAME_IDX]=${token}
        unset -n i_ref
        iuse_ref+=( "${pi_iuse}" )
    done

    iuse_out_var_name_ref=${iuse_var_name}

    if pkg_debug_enabled; then
        local -a all_iuse_strings=()
        local iuse_name pi_iuse_str
        local joined_iuse_string
        for iuse_name in "${iuse_ref[@]}"; do
            iuse_to_string "${iuse_name}" pi_iuse_str
            all_iuse_strings+=( "${pi_iuse_str}" )
        done
        join_by joined_iuse_string ' ' "${all_iuse_strings[@]}"
        pkg_debug_print "IUSE: ${joined_iuse_string}"
    fi
}

function __mcl_unset_array() {
    local array_name=${1}; shift
    local item_unset_func=${1}; shift

    if [[ ${array_name} = EMPTY_ARRAY ]]; then
        return 0
    fi
    local -n array_ref=${array_name}
    "${item_unset_func}" "${array_ref[@]}"
    unset -n array_ref
    unset "${array_name}"
}

fi
