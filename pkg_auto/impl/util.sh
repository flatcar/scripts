#!/bin/bash

if [[ -z ${__UTIL_SH_INCLUDED__:-} ]]; then
__UTIL_SH_INCLUDED__=x

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
    # shellcheck disable=SC2034 # it's a reference to external variable
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
    # shellcheck disable=SC2034 # it's a reference to external variable
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

THIS=$(realpath "${THIS}")
THIS_DIR=$(realpath "${THIS_DIR}")
dirname_out "${BASH_SOURCE[0]}" PKG_AUTO_IMPL_DIR
PKG_AUTO_IMPL_DIR=$(realpath "${PKG_AUTO_IMPL_DIR}")
# shellcheck disable=SC2034 # may be used by scripts sourcing this file
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
        # shellcheck disable=SC2034 # it's a reference to external variable
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
    # shellcheck disable=SC2034 # it's a reference to external variable
    out_ref=${t}
}

# Gets supported architectures.
#
# Params:
#
# 1 - name of an array variable, where the architectures will be stored
function get_valid_arches() {
    # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays
    local -n arches_ref=${1}; shift

    # shellcheck disable=SC2034 # it's a reference to external variable
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
    # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays
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

fi
