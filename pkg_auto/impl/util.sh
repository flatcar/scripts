#!/bin/bash

if [[ -z ${__UTIL_SH_INCLUDED__:-} ]]; then
__UTIL_SH_INCLUDED__=x

declare -gra EMPTY_ARRAY=()
declare -grA EMPTY_MAP=()

# Works like dirname, but without spawning new processes.
#
# Params:
#
# 1 - path to operate on
# 2 - name of a variable which will contain a dirname of the path
function dirname_out() {
    local path dir_var_name
    path=${1}; shift
    dir_var_name=${1}; shift
    local -n dir_ref=${dir_var_name}

    if [[ -z ${path} ]]; then
        dir_ref='.'
        return 0
    fi
    local cleaned_up dn
    # strip trailing slashes
    cleaned_up=${path%%*(/)}
    # strip duplicated slashes
    cleaned_up=${cleaned_up//+(\/)/\/}
    # strip last component
    dn=${cleaned_up%/*}
    if [[ -z ${dn} ]]; then
        dir_ref='/'
        return 0
    fi
    if [[ ${cleaned_up} = "${dn}" ]]; then
        dir_ref='.'
        return 0
    fi
    dir_ref=${dn}
}

# Works like basename, but without spawning new processes.
#
# Params:
#
# 1 - path to operate on
# 2 - name of a variable which will contain a basename of the path
function basename_out() {
    local path base_var_name
    path=${1}; shift
    base_var_name=${1}; shift
    local -n base_ref=${base_var_name}

    if [[ -z ${path} ]]; then
        base_ref=''
        return 0
    fi
    local cleaned_up dn
    # strip trailing slashes
    cleaned_up=${path%%*(/)}
    if [[ -z ${cleaned_up} ]]; then
        base_ref='/'
        return 0
    fi
    # strip duplicated slashes
    cleaned_up=${cleaned_up//+(\/)/\/}
    # keep last component
    dn=${cleaned_up##*/}
    base_ref=${dn}
}

if [[ ${BASH_SOURCE[-1]##*/} = 'util.sh' ]]; then
    THIS=${BASH}
    basename_out "${THIS}" THIS_NAME
    THIS_DIR=.
else
    THIS=${BASH_SOURCE[-1]}
    basename_out "${THIS}" THIS_NAME
    dirname_out "${THIS}" THIS_DIR
fi

declare -g THIS THIS_NAME THIS_DIR PKG_AUTO_IMPL_DIR PKG_AUTO_DIR
THIS=$(realpath "${THIS}")
THIS_DIR=$(realpath "${THIS_DIR}")
dirname_out "${BASH_SOURCE[0]}" PKG_AUTO_IMPL_DIR
PKG_AUTO_IMPL_DIR=$(realpath "${PKG_AUTO_IMPL_DIR}")
PKG_AUTO_DIR=$(realpath "${PKG_AUTO_IMPL_DIR}/..")

# Prints an info line.
#
# Params:
#
# @ - strings to print
function info() {
    printf '%s: %s\n' "${THIS_NAME}" "${*}"
}

# Prints info lines.
#
# Params:
#
# @ - lines to print
function info_lines() {
    printf '%s\n' "${@/#/"${THIS_NAME}: "}"
}

# Prints an info to stderr and fails the execution.
#
# Params:
#
# @ - strings to print
function fail() {
    info "${@}" >&2
    exit 1
}

# Prints infos to stderr and fails the execution.
#
# Params:
#
# @ - lines to print
function fail_lines() {
    info_lines "${@}" >&2
    exit 1
}

# Yells a message.
#
# Params:
#
# @ - strings to yell
function yell() {
    echo
    echo '!!!!!!!!!!!!!!!!!!'
    echo "    ${*}"
    echo '!!!!!!!!!!!!!!!!!!'
    echo
}

# Prints help. Help is taken from the lines prefixed with double
# hashes in the top sourcer of this file.
function print_help() {
    if [[ ${THIS} != "${BASH}" ]]; then
        grep '^##' "${THIS}" | sed -e 's/##[[:space:]]\?//'
    fi
}

# Joins passed strings with a given delimiter.
#
# Params:
#
# 1 - name of a variable that will contain the joined result
# 2 - delimiter
# @ - strings to join
function join_by() {
    local output_var_name delimiter first

    output_var_name=${1}; shift
    delimiter=${1}; shift
    first=${1-}
    if shift; then
        printf -v "${output_var_name}" '%s' "${first}" "${@/#/${delimiter}}";
    else
        local -n output_ref=${output_var_name}
        output_ref=''
    fi
}

# Checks if directory is empty, returns true if so, otherwise false.
#
# Params:
#
# 1 - path to a directory
function dir_is_empty() {
    local dir
    dir=${1}; shift

    [[ -z $(echo "${dir}"/*) ]]
}

# Just like diff, but ignores the return value.
function xdiff() {
    diff "${@}" || :
}

# Just like grep, but ignores the return value.
function xgrep() {
    grep "${@}" || :
}

# Strips leading and trailing whitespace from the passed parameter.
#
# Params:
#
# 1 - string to strip
# 2 - name of a variable where the result of stripping will be stored
function strip_out() {
    local l
    l=${1}; shift
    local -n out_ref=${1}; shift

    local t
    t=${l}
    t=${t/#+([[:space:]])}
    t=${t/%+([[:space:]])}
    out_ref=${t}
}

# Gets supported architectures.
#
# Params:
#
# 1 - name of an array variable, where the architectures will be stored
function get_valid_arches() {
    local -n arches_ref=${1}; shift

    arches_ref=( 'amd64' 'arm64' )
}

# Generates all pairs from a given sequence of strings. Each pair will
# be stored in the given variable and items in the pair will be
# separated by the given separator. For N strings, (N * N - N) / 2
# pairs will be generatated.
#
# Params:
#
# 1 - name of an array variable where the pairs will be stored
# 2 - separator string
# @ - strings
function all_pairs() {
    local -n pairs_ref=${1}; shift
    local sep=${1}; shift

    # indices in ${@} are 1-based, 0 gives script name or something
    local idx=1 next_idx

    pairs_ref=()
    while [[ ${idx} -lt ${#} ]]; do
        next_idx=$((idx + 1))
        while [[ ${next_idx} -le ${#} ]]; do
            pairs_ref+=( "${!idx}${sep}${!next_idx}" )
            next_idx=$((next_idx + 1))
        done
        idx=$((idx+1))
    done
}

# Does the set operation on two passed sets - both set differences and
# an intersection.
#
# Params:
#
# 1 - name of the first set variable
# 2 - name of the second set variable
# 3 - name of the set variable that will contain elements that exist
#     in first set, but not the second
# 4 - name of the set variable that will contain elements that exist
#     in second set, but not the first
# 5 - name of the set variable that will contain elements that exist
#     in both first and second sets
function sets_split() {
    local -n first_set_ref=${1}; shift
    local -n second_set_ref=${1}; shift
    local -n only_in_first_set_ref=${1}; shift
    local -n only_in_second_set_ref=${1}; shift
    local -n common_set_ref=${1}; shift

    only_in_first_set_ref=()
    only_in_second_set_ref=()
    common_set_ref=()

    local item mark

    for item in "${!first_set_ref[@]}"; do
        mark=${second_set_ref["${item}"]:-}
        if [[ -z ${mark} ]]; then
            only_in_first_set_ref["${item}"]=x
        else
            common_set_ref["${item}"]=x
        fi
    done

    for item in "${!second_set_ref[@]}"; do
        mark=${first_set_ref["${item}"]:-}
        if [[ -z ${mark} ]]; then
            only_in_second_set_ref["${item}"]=x
        fi
    done
}

declare -gi __UTIL_SH_COUNTER=0

# Generates a globally unique name for a variable. Can be given a
# prefix to override the default __PA_VAR one.
#
# Params:
#
# (optional) a prefix
# 1 - name of a variable, where the generated name will be stored
function gen_varname() {
    local prefix='__PA_VAR' # pa = pkg-auto
    if [[ ${#} -gt 1 ]]; then
        # we passed a prefix
        prefix=${1}; shift
    fi
    local -n name_ref=${1}; shift

    name_ref="${prefix}_${__UTIL_SH_COUNTER}"
    __UTIL_SH_COUNTER=$((__UTIL_SH_COUNTER + 1))
}

# Declares variables with a given initializer.
#
# Params:
#
# @: flags passed to declare, followed by variable names, followed by
# an initializer
function struct_declare() {
    local -a args=()
    while [[ $# -gt 0 ]]; do
        if [[ ${1} != -* ]]; then
            break
        fi
        args+=( "${1}" )
        shift
    done
    if [[ ${#} -lt 2 ]]; then
        fail "bad use of struct_declare"
    fi
    local definition=${*: -1}
    set -- "${@:1:$((${#} - 1))}"
    set -- "${@/%/=${definition}}"
    declare "${args[@]}" "${@}"
}

function declare_enum() {
    local -a for_declare=()
    local idx_name
    local -i idx=0
    for idx_name; do
        for_declare+=( "${idx_name}=${idx}" )
        ((++idx))
    done
    declare -gri "${for_declare[@]}"
}

function struct_unset() {
    if [[ ${1} = '---' ]]; then
        shift
    else
        local -a pairs=()
        while [[ ${1} != '---' ]]; do
            pairs+=( "${1}" )
            shift
        done
        shift # remove ---
        local item_var_name idx_name desc unset_func member
        local -i idx len=${#pairs[@]} item_idx
        for item_var_name; do
            local -n item_ref=${item_var_name}
            for ((idx=0; idx < len; idx = idx + 2)); do
                idx_name=${pairs[idx]}
                item_idx=${!idx_name}
                member=${item_ref[item_idx]}
                desc=${pairs[$((idx + 1))]}
                case ${desc} in
                    '-a'*)
                        if [[ ${member} != 'EMPTY_ARRAY' ]]; then
                            unset_func=${desc:2}
                            if [[ ${unset_func} != '--' ]]; then
                                local -n array_ref=${member}
                                "${unset_func}" "${array_ref[@]}"
                                unset -n array_ref
                            fi
                            unset "${member}"
                        fi
                        ;;
                    '-A'*)
                        if [[ ${member} != 'EMPTY_MAP' ]]; then
                            unset_func=${desc:2}
                            if [[ ${unset_func} != '--' ]]; then
                                local -n map_ref=${member}
                                "${unset_func}" "${map_ref[@]}"
                                unset -n map_ref
                            fi
                            unset "${member}"
                        fi
                        ;;
                    '--')
                        # simple scalar, nothing to do
                        :
                        ;;
                    *)
                        unset_func=${desc}
                        "${unset_func}" "${member}"
                        ;;
                esac
            done
        done
    fi

    unset "${@}"
}

function array_single_unset() {
    local var_name=${1}; shift
    local unset_elem=${1}; shift
    if [[ ${var_name} == 'EMPTY_ARRAY' ]]; then
        return 0
    fi
    local -n ref=${var_name}
    if [[ ${unset_elem} != '--' ]]; then
        "${unset_elem}" "${ref[@]}"
    fi
    unset -n ref
    unset "${var_name}"
}

function map_single_unset() {
    local var_name=${1}; shift
    local key_unset=${1}; shift
    local value_unset=${1}; shift
    if [[ ${var_name} == 'EMPTY_MAP' ]]; then
        return 0
    fi
    local -n ref=${var_name}
    if [[ ${key_unset} != '--' ]]; then
        "${key_unset}" "${!ref[@]}"
    fi
    if [[ ${value_unset} != '--' ]]; then
        "${value_unset}" "${ref[@]}"
    fi
    unset -n ref
    unset "${var_name}"
}

function assign_struct_members() {
    local -n ref=${1}; shift
    local -i idx
    local item
    while [[ ${#} -gt 1 ]]; do
        idx=${!1}
        item=${2}
        shift 2
        ref[idx]=${item}
    done
}

function copy_structs() {
    local -n dest_ref=${1}; shift
    local -n src_ref=${1}; shift

    local -i idx
    local funcs val cs_container_var_name item item2 cs_item_var_name
    local declare_func copy_func declare_func2 copy_func2 func_pair1 func_pair2
    while [[ ${#} -gt 1 ]]; do
        idx=${!1}
        funcs=${2}
        shift 2
        val=${src_ref[idx]}
        case ${funcs} in
            '-a'*)
                funcs=${funcs:2}
                local -n src_array_ref=${val}
                if [[ ${#src_array_ref[@]} -eq 0 ]]; then
                    cs_container_var_name='EMPTY_ARRAY'
                else
                    gen_varname cs_container_var_name
                    if [[ ${funcs} = '--' ]]; then
                        declare -ga "${cs_container_var_name}=( ${src_array_ref[*]@Q} )"
                    else
                        declare_func=${funcs%%,*}
                        copy_func=${funcs#*,}
                        declare -ga "${cs_container_var_name}=()"
                        local -n dest_array_ref=${cs_container_var_name}
                        for item in "${src_array_ref[@]}"; do
                            gen_varname cs_item_var_name
                            "${declare_func}" "${cs_item_var_name}"
                            "${copy_func}" "${cs_item_var_name}" "${item}"
                            dest_array_ref+=( "${cs_item_var_name}" )
                        done
                        unset -n dest_array_ref
                    fi
                fi
                unset -n src_array_ref
                dest_ref[idx]=${cs_container_var_name}
                ;;
            '-A'*)
                funcs=${funcs:2}
                local -n src_map_ref=${val}
                if [[ ${#src_map_ref[@]} ]]; then
                    cs_container_var_name='EMPTY_MAP'
                else
                    gen_varname cs_container_var_name
                    declare -gA "${cs_container_var_name}=()"
                    local -n dest_map_ref=${cs_container_var_name}
                    if [[ ${funcs} = '--' ]]; then
                        for item in "${!src_map_ref[@]}"; do
                            item2=${src_map_ref["${item}"]}
                            dest_map_ref["${item}"]=${item2}
                        done
                    else
                        declare_func=${funcs%%,*}
                        copy_func=${funcs#*,}
                        for item in "${!src_map_ref[@]}"; do
                            item2=${src_map_ref["${item}"]}
                            gen_varname cs_item_var_name
                            "${declare_func}" "${cs_item_var_name}"
                            "${copy_func}" "${cs_item_var_name}" "${item2}"
                            dest_map_ref["${item}"]=${item2}
                        done
                    fi
                    unset -n dest_map_ref
                fi
                unset -n src_map_ref
                dest_ref[idx]=${cs_container_var_name}
                ;;
            '--')
                dest_ref[idx]=${val}
                ;;
            *)
                :
                declare_func=${funcs%%,*}
                copy_func=${funcs#*,}
                gen_varname cs_item_var_name
                "${declare_func}" "${cs_item_var_name}"
                "${copy_func}" "${cs_item_var_name}" "${val}"
                dest_ref[idx]=${cs_item_var_name}
                ;;
        esac
    done
}

function get_struct_members() {
    local -n ref=${1}; shift
    local -i idx
    local out_var_name
    while [[ ${#} -gt 1 ]]; do
        idx=${!1}
        out_var_name=${2}
        shift 2
        local -n out_ref=${out_var_name}
        out_ref=${ref[idx]}
        unset -n out_ref
    done
}

function array_ref_len() {
    local -n arr=${1}; shift
    local -n len_ref=${1}; shift

    len_ref=${#arr[@]}
}

function array_ref_get() {
    local -n arr=${1}; shift
    local -i idx=${1}; shift
    local -n out_ref=${1}; shift

    out_ref=${arr[idx]}
}

function assign_to_ref() {
    local -n ref=${1}; shift
    ref=${1}
}

function get_num_proc() {
    local -n num_proc_ref=${1}; shift
    local -i num_proc=1 rv=1

    # stolen from portage
    [[ rv -eq 0 ]] || { rv=0; num_proc=$(getconf _NPROCESSORS_ONLN 2>/dev/null) || rv=1; }
    [[ rv -eq 0 ]] || { rv=0; num_proc=$(sysctl -n hw.ncpu 2>/dev/null) || rv=1; }
    # stolen from my head
    [[ rv -eq 0 ]] || { rv=0; num_proc=$(nproc) || rv=1; }
    # stolen from common.sh
    [[ rv -eq 0 ]] || { rv=0; num_proc=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null) || rv=1; }
    [[ rv -eq 0 ]] || { rv=0; num_proc=1; }

    num_proc_ref=${num_proc}
}

# Escapes special characters in the passed string so the string can be
# used as a regexp in the s/regexp/replacement/ sed command to match
# the passed string literally.
#
# Params:
#
# 1 - string to escape
# 2 - separator that will be used in sed using the escaped string
# 3 - name of a variable, where the escaped string will be stored
function escape_sed_regexp() {
    # sed -e 's/[]\/$*.^[]/\\&/g'
    _escape_sed_impl "${@}" '[' ']' '$' '*' '.' '^'
}

# Escapes special characters in the passed string so the string can be
# used as a replacement in the s/regexp/replacement/ sed command to
# perform replacements the passed string literally.
#
# Params:
#
# 1 - string to escape
# 2 - separator that will be used in sed using the escaped string
# 3 - name of a variable, where the escaped string will be stored
function escape_sed_replacement() {
    # sed -e 's/[\/&]/\\&/g'
    _escape_sed_impl "${@}" '&'
}

function _escape_sed_impl() {
    local r=${1}; shift
    local sed_separator=${1}; shift
    local -n esi_escaped=${1}; shift
    # rest are entities to escape

    # escape all preexisting backslashes first
    local l=${r//'\'/'\\'} c
    for c in "${@}" "${sed_separator}"; do
        l=${l//"${c}"/'\'"${c}"}
    done
    esi_escaped=${l}
}

# Runs a command with time, stores the time stat in the passed
# variable. Only realtime is stored - used TIMEFORMAT is %slR.
#
# It should be noted that the command will run in a subshell, so if
# the command is a bash function modifying some global variables,
# these modifications will not be seen by the called of timed_run.
#
# Params:
#
# 1 - name of the variable where the time is stored
# @ - command and parameters
function timed_run() {
    local -n timeinfo_ref=${1}; shift
    local -i outfd errfd rv=0

    exec {outfd}>&1 {errfd}>&2
    timeinfo_ref=$(TIMEFORMAT='%3lR'; { time "${@}" 1>&${outfd} 2>&${errfd}; } 2>&1) || rv=$?
    exec {outfd}>&- {errfd}>&-
    return "${rv}"
}

fi

function dump_var() {
    local ignore_if_not_var=''
    if [[ ${1} = '-i' ]]; then
        ignore_if_not_var=x; shift
    fi
    local var_name=${1}; shift
    local indent=''
    if [[ ${#} -gt 0 ]]; then
        indent=${1}; shift
    fi
    local name=${var_name}
    if [[ ${#} -gt 0 ]]; then
        name=${1}; shift
    fi
    local kw type assign
    local -i rv=0

    read -r kw type assign < <(declare -p "${var_name}" 2>/dev/null) || rv=${?}
    if [[ rv -ne 0 ]]; then
        if [[ -n ${ignore_if_not_var} ]]; then
            return 0
        fi
        fail "no such variable to dump: ${var_name}"
    fi

    case ${type} in
        '-'*'a'*) type=array;;
        '-'*'A'*) type=map;;
        *) type=scalar;;
    esac

    echo "${indent}${name} (${type}): ${assign#*=}"
    case ${type} in
        'array')
            local -n array_ref=${var_name}
            local array_item
            local -i idx=0
            for array_item in "${array_ref[@]}"; do
                dump_var -i "${array_item}" "${indent}  " "${var_name}[${idx}]"
                ((++idx))
            done
            unset -n array_ref
            ;;
        'map')
            local -n map_ref=${var_name}
            local map_key map_value
            for map_key in "${!map_ref[@]}"; do
                dump_var -i "${map_key}" "${indent}  " "key ${map_key} in ${var_name}"
                map_value=${map_ref["${map_key}"]}
                dump_var -i "${map_value}" "${indent}  " "${var_name}[${map_key}]"
            done
            unset -n map_ref
            ;;
    esac
}

# Invokes sort with C locale. Meant to be used in bash pipelines.
#
# Params:
#
# @ - additional parameters to passed to sort
function csort() {
    LC_ALL=C sort "${@}"
}
