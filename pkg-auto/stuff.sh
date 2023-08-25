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

THIS=$(realpath "${THIS}")
THIS_DIR=$(realpath "${THIS_DIR}")

function info() {
    printf '%s: %s' "${THIS_NAME}" "${*}"
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

_no_cleanups=''
_cleanup_kind=''

_file_cleanup_file=''
_file_add_cleanup() {
    local fac_cleanup_dir tmpfile
    dirname_out "${_file_cleanup_file}" fac_cleanup_dir
    tmpfile=$(mktemp -p "${fac_cleanup_dir}")
    printf '%s\n' "${@}" >${tmpfile}
    if [[ -f "${_file_cleanup_file}" ]]; then
        cat "${_file_cleanup_file}" >>${tmpfile}
    fi
    mv -f "${tmpfile}" "${_file_cleanup_file}"
}

_trap_cleanup_actions=''
function _trap_add_cleanup() {
    local tac_joined
    join_by tac_joined ' ; ' "${@}"
    _trap_cleanup_actions="${tac_joined} ; ${_trap_cleanup_actions}"
    trap "${_trap_cleanup_actions}" EXIT
}

function _ignore_add_cleanup() {
    :
}

# 1: kind of cleanup
#
# kinds:
# - file: requires extra argument about cleanup file location
# - trap: executed on shell exit
# - ignore: noop
function setup_cleanups {
    local kind
    kind=${1}; shift

    if [[ -n "${_cleanup_kind}" ]]; then
        fail "cannot set cleanups to '${kind}', they are already set up to '${_cleanup_kind}'"
    fi

    case ${kind} in
        'file')
            if [[ ${#} -ne 1 ]]; then
                fail 'missing cleanup file location argument for file cleanups'
            fi
            _file_cleanup_file=${1};
            ;;
        'trap'|'ignore')
            :
            ;;
        *)
            fail "unknown cleanup kind '${kind}'"
            ;;
    esac
    _cleanup_kind=${kind}
}

function add_cleanup {
    if [[ -z "${_cleanup_kind}" ]]; then
        _cleanup_kind='trap'
    fi
    local add_func="${_cleanup_kind}_add_cleanup"

    "${add_func}" "${@}"
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
