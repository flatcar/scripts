#!/bin/bash

if [[ -z ${__STUFF_SH_INCLUDED__:-} ]]; then
__STUFF_SH_INCLUDED__=x

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
    if [[ ${cleaned_up} = "${dn}" ]]; then
        dir_ref='.'
        return 0
    fi
    # shellcheck disable=SC2034 # it's a reference to external variable
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
    # shellcheck disable=SC2034 # it's a reference to external variable
    base_ref=${dn}
}

if [[ ${BASH_SOURCE[-1]##*/} = 'stuff.sh' ]]; then
    THIS="${BASH}"
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
PKG_AUTO_DIR=$(realpath "${PKG_AUTO_IMPL_DIR}")

function info() {
    printf '%s: %s\n' "${THIS_NAME}" "${*}"
}

function info_lines() {
    printf '%s\n' "${@/#/"${THIS_NAME}: "}"
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
    if [[ ${THIS} != "${BASH}" ]]; then
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
        # shellcheck disable=SC2034 # it's a reference to external variable
        output_ref=''
    fi
}

_cleanup_kind=''

# file cleanups

function _file_setup_cleanups() {
    if [[ ${#} -ne 1 ]]; then
        fail 'missing cleanup file location argument for file cleanups'
    fi

    declare -g _file_cleanup_file
    _file_cleanup_file=$(realpath "${1}"); shift
    add_cleanup "rm -f ${_file_cleanup_file@Q}"
}

function _file_add_cleanup() {
    local fac_cleanup_dir tmpfile
    dirname_out "${_file_cleanup_file}" fac_cleanup_dir

    tmpfile=$(mktemp -p "${fac_cleanup_dir}")
    printf '%s\n' "${@}" >"${tmpfile}"
    if [[ -f "${_file_cleanup_file}" ]]; then
        cat "${_file_cleanup_file}" >>"${tmpfile}"
    fi
    mv -f "${tmpfile}" "${_file_cleanup_file}"
}

# trap cleanups

function _trap_update_trap() {
    # shellcheck disable=SC2064 # using double quotes on purpose instead of single quotes
    trap "${_trap_cleanup_actions}" EXIT
}

function _trap_setup_cleanups() {
    declare -g _trap_cleanup_actions
    _trap_cleanup_actions=':'

    declare -g -A _trap_cleanup_snapshots
    _trap_cleanup_snapshots=()

    _trap_update_trap
}

function _trap_add_cleanup() {
    local tac_joined
    join_by tac_joined ' ; ' "${@/%/' || :'}"
    _trap_cleanup_actions="${tac_joined} ; ${_trap_cleanup_actions}"
    _trap_update_trap
}

# ignore cleanups

function _ignore_setup_cleanups() {
    :
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
function setup_cleanups() {
    local kind
    kind=${1}; shift

    if [[ -n "${_cleanup_kind}" ]]; then
        fail "cannot set cleanups to '${kind}', they are already set up to '${_cleanup_kind}'"
    fi

    _ensure_valid_cleanup_kind "${kind}"
    _cleanup_kind=${kind}
    _call_cleanup_func setup_cleanups "${@}"
}

function add_cleanup() {
    _call_cleanup_func add_cleanup "${@}"
}

function _ensure_valid_cleanup_kind() {
    local kind
    kind=${1}; shift

    local -a functions=(
        setup_cleanups
        add_cleanup
    )

    local func
    for func in "${functions[@]/#/_${kind}_}"; do
        if ! declare -pF "${func}" >/dev/null 2>/dev/null; then
            fail "kind '${kind}' is not a valid cleanup kind, function '${func}' is not defined"
        fi
    done
}

function _call_cleanup_func() {
    local func_name
    func_name=${1}; shift
    if [[ -z "${_cleanup_kind}" ]]; then
        _cleanup_kind='trap'
    fi

    local func
    func="_${_cleanup_kind}_${func_name}"

    "${func}" "${@}"
}

function dir_is_empty() {
    local dir
    dir=${1}; shift

    [[ -z $(echo "${dir}"/*) ]]
}

function xdiff() {
    diff "${@}" || :
}

function xgrep() {
    grep "${@}" || :
}

fi
