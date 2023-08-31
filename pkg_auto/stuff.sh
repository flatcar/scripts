#!/bin/bash

if [[ -z ${__STUFF_SH_INCLUDED__:-} ]]; then
__STUFF_SH_INCLUDED__=x

if [[ ${BASH_SOURCE[-1]##*/} = 'stuff.sh' ]]; then
    THIS="${BASH}"
    THIS_NAME=$(basename "${THIS}")
    THIS_DIR=.
else
    THIS=${BASH_SOURCE[-1]}
    THIS_NAME=$(basename "${THIS}")
    THIS_DIR=$(dirname "${THIS}")
fi

THIS=$(realpath "${THIS}")
THIS_DIR=$(realpath "${THIS_DIR}")

function info() {
    printf '%s: %s\n' "${THIS_NAME}" "${*}"
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
    _file_cleanup_file=${1}; shift
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

function _file_snapshot_cleanup() {
    local snapshot_var_name
    snapshot_var_name=${1}; shift
    local -n snapshot_ref="${snapshot_var_name}"

    local dir
    dirname_out "${_file_cleanup_file}" dir
    local name
    basename_out "${_file_cleanup_file}" name

    snapshot_ref=$(mktemp -p "dir" "${name}-snapshot-XXXXXXXXXX")
    cp -a "${_file_cleanup_file}" "${snapshot_ref}"
}

function _file_revert_to_cleanup_snapshot() {
    local snapshot
    snapshot=${1}; shift

    mv -f "${snapshot}" "${_file_cleanup_file}"
}

function _file_drop_cleanup_snapshot() {
    local snapshot
    snapshot=${1}; shift

    rm -f "${snapshot}"
}

function _file_stash_cleanups() {
    local stash_file
    stash_file=${1}; shift

    echo "${_file_cleanup_file}" >>"${stash_file}"
    unset _file_cleanup_file
}

function _file_resume_cleanups() {
    local stash_file
    stash_file=${1}; shift

    declare -g _file_cleanup_file

    local line
    {
        read -r line || fail "corrupted cleanups stash file '${stash_file}'" # ignore first line
        read -r _file_cleanup_file || fail "no cleanup file saved in cleanup stash file '${stash_file}'"
    } <"${stash_file}"
}

# trap cleanups

function _trap_setup_cleanups() {
    declare -g _trap_cleanup_actions
    _trap_cleanup_actions=':'

    declare -g -A _trap_cleanup_snapshots
    _trap_cleanup_snapshots=()

    trap '${_trap_cleanup_actions}' EXIT
}

function _trap_add_cleanup() {
    local tac_joined
    join_by tac_joined ' ; ' "${@}"
    _trap_cleanup_actions="${tac_joined} ; ${_trap_cleanup_actions}"
}

function _trap_snapshot_cleanup() {
    local snapshot_var_name
    snapshot_var_name=${1}; shift
    local -n snapshot_ref="${snapshot_var_name}"

    local key
    while true; do
        key="snapshot-${RANDOM}"
        value=${_trap_cleanup_snapshots["${key}"]:-}
        if [[ -z "${value}" ]]; then
            break
        fi
    done
    snapshot_ref=${key}
    _trap_cleanup_snapshots["${key}"]=${_trap_cleanup_actions}
}

function _trap_revert_to_cleanup_snapshot() {
    local snapshot
    snapshot=${1}; shift

    _trap_cleanup_actions=${_trap_cleanup_snapshots["${snapshot}"]}
    unset _trap_cleanup_snapshots["${snapshot}"]
}

function _trap_drop_cleanup_snapshot() {
    local snapshot
    snapshot=${1}; shift

    unset _trap_cleanup_snapshots["${snapshot}"]
}

function _trap_stash_cleanups() {
    local stash_file
    stash_file=${1}; shift

    local name line
    {
        trap - EXIT
        echo "${_trap_cleanup_actions}"
        unset _trap_cleanup_actions

        for name in "${!_trap_cleanup_snapshots[@]}"; do
            line=${_trap_cleanup_snapshots["${name}"]}
            echo "${name}"
            echo "${line}"
        done
    }  >>"${stash_file}"
}

function _trap_resume_cleanups() {
    local stash_file
    stash_file=${1}; shift

    declare -g _trap_cleanup_actions
    _trap_cleanup_actions=''

    declare -g -A _trap_cleanup_snapshots
    _trap_cleanup_snapshots=()

    local line name
    {
        read -r line || fail "corrupted cleanups stash file '${stash_file}'" # ignore first line
        read -r _trap_cleanup_actions || fail "no cleanup actions saved in cleanup stash file '${stash_file}'"
        while read -r name; do
            read -r line || fail "no cleanup actions for snapshot '${name}' saved in cleanup stash file '${stash_file}'"
            _trap_cleanup_snapshots["${name}"]=${line}
    } <"${stash_file}"
}

# ignore cleanups

function _ignore_setup_cleanups() {
    :
}

function _ignore_add_cleanup() {
    :
}

function _ignore_snapshot_cleanup() {
    :
}

function _ignore_revert_to_cleanup_snapshot() {
    :
}

function _ignore_drop_cleanup_snapshot() {
    :
}

function _ignore_stash_cleanups() {
    :
}

function _ignore_resume_cleanups() {
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

function _ensure_valid_cleanup_kind() {
    local kind
    kind=${1}; shift

    local -a functions=(
        setup_cleanups
        add_cleanup
        snapshot_cleanup
        revert_to_cleanup_snapshot
        drop_cleanup_snapshot
        resume_cleanups
    )

    local func
    for func in "${functions[@]/#/_${kind}_"; do
        if ! declare -pF "${func}" >/dev/null 2>/dev/null; then
            fail "kind '${kind}' is not a valid cleanup kind, function '${func}' is not defined"
        fi
    done
}

function stash_cleanups() {
    local stash_file
    stash_file=${1}; shift

    echo "${_cleanup_kind}" >"${stash_file}"

    _call_cleanup_func stash_cleanups "${stash_file}"
    unset _cleanup_kind
}

function resume_cleanups() {
    local stash_file
    stash_file=${1}; shift

    local kind
    read -r kind <"${stash_file}" || fail "corrupted cleanups stash file '${stash_file}'"
    _ensure_valid_cleanup_kind "${kind}"
    _cleanup_kind=${kind}
    _call_cleanup_func resume_cleanups "${stash_file}"
}

function _call_cleanup_func() {
    local func_name
    func_name=${1}; shift
    if [[ -z "${_cleanup_kind}" ]]; then
        _cleanup_kind='trap'
    fi

    local func
    func="_${cleanup_kind}_${func_name}"

    "${func}" "${@}"
}

function add_cleanup() {
    _call_cleanup_func add_cleanup "${@}"
}

function snapshot_cleanup() {
    _call_cleanup_func snapshot_cleanup "${@}"
}

function revert_to_cleanup_snapshot() {
    _call_cleanup_func revert_to_cleanup_snapshot "${@}"
}

function drop_cleanup_snapshot() {
    _call_cleanup_func drop_cleanup_snapshot "${@}"
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

fi
