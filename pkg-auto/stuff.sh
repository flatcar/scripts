#!/bin/bash

if [[ -z ${__STUFF_SH_INCLUDED__:-} ]]; then
__STUFF_SH_INCLUDED__=x

if [[ ${BASH_SOURCE[-1]##*/} = 'stuff.sh' ]]; then
    THIS="${BASH}"
    THIS_NAME=$(basename "${THIS}")
    THIS_DIR=.
else
    THIS=${BASH_SOURCE[-1]##*/}
    THIS_NAME=$(basename "${THIS}")
    THIS_DIR=$(dirname "${THIS}")
fi

THIS_DIR=$(realpath "${THIS_DIR}")

function info() {
    printf '%s: %s' "${this_name}" "${*}"
}

function fail() {
    info "${@}" >&2
    exit 1
}

function yell() {
	echo
	echo '!!!!!!!!!!!!!!!!!!'
	echo "    ${*}"
	echo '!!!!!!!!!!!!!!!!!!'
	echo
}

function print_help() {
    if [[ ${THIS} != ${BASH} ]]; then
        grep '^##' "${THIS}" | sed -e 's/##[[:space:]]*//'
    fi
}

function join_by() {
    local output_var_name delimiter first

    output_var_name=${1}; shift
    delimiter=${1}; shift
    first=${1-}
    if shift; then
        printf -v "${output_var_name}" '%s' "${first}" "${@/#/${delimiter}}";
    else
        local -n output_ref="${output_var_name}"
        output_ref=''
    fi
}

_cleanup_actions=''
_no_cleanups=''

function ignore_cleanups {
    _no_cleanups=x
}

function add_cleanup {
    if [[ -n "${_no_cleanups}" ]]; then
        return
    fi
    local joined
    joined=$(join_by ' ; ' "${@}")
    _cleanup_actions="${joined} ; ${_cleanup_actions}"
    trap "${_cleanup_actions}" EXIT
}

function dirname_out() {
    local path dir_var_name
    path=${1}; shift
    dir_var_name=${1}; shift
    local -n dir_ref="${dir_var_name}"

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
    if [[ ${cleaned_up} = ${dn} ]]; then
        dir_ref='.'
        return 0
    fi
    dir_ref=${dn}
}

function basename_out() {
    local path base_var_name
    path=${1}; shift
    base_var_name=${1}; shift
    local -n base_ref="${base_var_name}"

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

fi
