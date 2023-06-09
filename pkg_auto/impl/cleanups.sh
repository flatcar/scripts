#!/bin/bash

#
# Cleanups
#
# This is basically a command stack to be executed in some deferred
# time. So last command added will be the first to be executed at
# cleanup time.
#
# Cleanups are implemented through two functions, setup_cleanups and
# add_cleanup, prefixed with _${type}_. So for type "foo" the
# functions would be _foo_setup_cleanups and _foo_add_cleanup.
#
# setup_cleanup may take some extra parameters that are specific to
# the type. For example file type takes a path where the commands will
# be stored.
#
# add_cleanup takes one or more command to add to the cleanup stack.
#

if [[ -z ${__CLEANUPS_SH_INCLUDED__:-} ]]; then
__CLEANUPS_SH_INCLUDED__=x

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

# Sets up cleanup stack of a given type. A type may need some extra
# parameter, which comes after a comma. Possible types are:
#
# - file: requires extra argument about cleanup file location; an
#   example could be "file,/path/to/cleanups-file"
# - trap: executed on shell exit
# - ignore: noop
#
# Params:
#
# 1 - type of cleanup
function setup_cleanups() {
    local kind
    kind=${1}; shift

    if [[ -n ${_cleanups_sh_cleanup_kind_:-} ]]; then
        fail "cannot set cleanups to '${kind}', they are already set up to '${_cleanups_sh_cleanup_kind_}'"
    fi

    declare -g _cleanups_sh_cleanup_kind_

    _ensure_valid_cleanups_sh_cleanup_kind_ "${kind}"
    _cleanups_sh_cleanup_kind_=${kind}
    _call_cleanup_func setup_cleanups "${@}"
}

# Adds commands to the cleanup stack.
#
# Params:
#
# @ - commands, one per parameter
function add_cleanup() {
    _call_cleanup_func add_cleanup "${@}"
}

#
# Implementation details.
#

# "file" cleanups

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

# "trap" cleanups

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

# "ignore" cleanups

function _ignore_setup_cleanups() {
    :
}

function _ignore_add_cleanup() {
    :
}

function _ensure_valid_cleanups_sh_cleanup_kind_() {
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
    if [[ -z "${_cleanups_sh_cleanup_kind_}" ]]; then
        _cleanups_sh_cleanup_kind_='trap'
    fi

    local func
    func="_${_cleanups_sh_cleanup_kind_}_${func_name}"

    "${func}" "${@}"
}

fi
