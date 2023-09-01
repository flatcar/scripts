#!/bin/bash

if [[ -z ${__MVM_SH_INCLUDED__:-} ]]; then
__MVM_SH_INCLUDED__=x

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"

# mvm - multivalue map
# mvc - multivalue container, a value stored in mvm

MVM_COUNTER=0

# array mvm, default
function mvm_mvc_array_constructor() {
    local array_var_name
    array_var_name=${1}; shift

    declare -g -a "${array_var_name}"

    local -n array_ref="${array_var_name}"
    array_ref=()
}

function mvm_mvc_array_destructor() {
    local array_var_name
    array_var_name=${1}; shift

    unset "${array_var_name}"
}

function mvm_mvc_array_adder() {
    local array_var_name
    array_var_name=${1}; shift
    # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays
    local -n array_ref="${array_var_name}"

    array_ref+=( "${@}" )
}

# iteration_helper is optional
function mvm_mvc_array_iteration_helper() {
    local key array_var_name callback
    key=${1}; shift
    array_var_name=${1}; shift
    callback=${1}; shift
    # rest are extra args passed to cb

    # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays
    local -n array_ref="${array_var_name}"
    "${callback}" "${@}" "${key}" "${array_var_name}" "${array_ref[@]}"
}

# map mvm
function mvm_mvc_map_constructor() {
    local map_var_name
    map_var_name=${1}; shift

    declare -g -A "${map_var_name}"

    local -n map_ref="${map_var_name}"
    map_ref=()
}

function mvm_mvc_map_destructor() {
    local map_var_name
    map_var_name=${1}; shift

    unset "${map_var_name}"
}

function mvm_mvc_map_adder() {
    local map_var_name
    map_var_name=${1}; shift
    # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays
    local -n map_ref="${map_var_name}"

    while [[ ${#} -gt 1 ]]; do
        # shellcheck disable=SC2034 # it's a reference to external variable
        map_ref["${1}"]=${2}
        shift 2
    done
}

# set mvm
function mvm_mvc_set_constructor() {
    local set_var_name
    set_var_name=${1}; shift

    declare -g -A "${set_var_name}"

    local -n set_ref="${set_var_name}"
    set_ref=()
}

function mvm_mvc_set_destructor() {
    local set_var_name
    set_var_name=${1}

    unset "${set_var_name}"
}

function mvm_mvc_set_adder() {
    local set_var_name
    set_var_name=${1}; shift

    # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays
    local -n set_ref="${set_var_name}"
    while [[ ${#} -gt 0 ]]; do
        set_ref["${1}"]=x
        shift
    done
}

# iteration_helper is optional
function mvm_mvc_set_iteration_helper() {
    local key map_var_name callback

    key=${1}; shift
    set_var_name=${1}; shift
    callback=${1}; shift
    # rest are extra args passed to cb

    # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays
    local -n set_ref="${set_var_name}"
    "${callback}" "${@}" "${key}" "${set_var_name}" "${!set_ref[@]}"
}

# mvm functions
function mvm_declare() {
    local mvm_var_name
    mvm_var_name=${1}; shift

    local value_handler_prefix
    value_handler_prefix=''
    if [[ ${#} -gt 0 ]]; then
        if [[ ${1} != '--' ]]; then
            value_handler_prefix=${1}
            shift
        fi
        if [[ ${#} -gt 0 ]]; then
            if [[ ${1} != '--' ]]; then
                fail "missing double-dash separator between optional value handler prefix and extra key value pairs for '${mvm_var_name}'"
            fi
            shift
        fi
    fi
    if [[ -z ${value_handler_prefix} ]]; then
        value_handler_prefix=mvm_mvc_array
    fi
    # rest are key value pairs for extras

    local constructor destructor adder iteration_helper
    constructor="${value_handler_prefix}_constructor"
    destructor="${value_handler_prefix}_destructor"
    adder="${value_handler_prefix}_adder"
    iteration_helper="${value_handler_prefix}_iteration_helper"

    local func
    for func in "${constructor}" "${destructor}" "${adder}"; do
        if ! declare -pF "${func}" >/dev/null 2>/dev/null; then
            fail "'${func}' is not a function, is '${value_handler_prefix}' a valid prefix?"
        fi
    done

    if ! declare -pF "${iteration_helper}" >/dev/null 2>/dev/null; then
        iteration_helper=''
    fi

    local extras_idx storage_idx extras_map_var_name storage_map_var_name
    extras_idx=$((MVM_COUNTER))
    storage_idx=$((MVM_COUNTER + 1))
    extras_map_var_name="mvm_stuff_${extras_idx}"
    storage_map_var_name="mvm_stuff_${storage_idx}"

    MVM_COUNTER=$((MVM_COUNTER + 2))

    declare -g -A "${mvm_var_name}" "${extras_map_var_name}" "${storage_map_var_name}"

    local -n storage_map_ref="${storage_map_var_name}"
    storage_map_ref=()

    local -n mvm_ref="${mvm_var_name}"
    # shellcheck disable=SC2034 # it's a reference to external variable
    mvm_ref=(
        ['name']="${mvm_var_name}"
        ['constructor']="${constructor}"
        ['destructor']="${destructor}"
        ['adder']="${adder}"
        ['iteration_helper']="${iteration_helper}"
        ['counter']=0
        ['extras']="${extras_map_var_name}"
        ['storage']="${storage_map_var_name}"
    )
    local -n extras_map_ref="${extras_map_var_name}"
    while [[ ${#} -gt 1 ]]; do
        extras_map_ref["${1}"]=${2}
        shift 2
    done
    if [[ ${#} -gt 0 ]]; then
        fail "odd number of parameters for extra key value information for '${mvm_var_name}'"
    fi
}

function mvm_call() {
    local name func
    name=${1}; shift
    func=${1}; shift
    # rest are func args

    # The "mvm" variable can be used by ${func} now.
    local -n mvm="${name}"
    "${func}" "${@}"
}

function __mvm_mvc_name() {
    local name counter mvc_name_var_name
    name=${1}; shift
    counter=${1}; shift
    mvc_name_var_name=${1}; shift
    local -n mvc_name_ref="${mvc_name_var_name}"

    # shellcheck disable=SC2034 # it's a reference to external variable
    mvc_name_ref="mvm_${name}_mvc_${counter}"
}

function mvm_unset() {
    # TODO: debug, drop it
    echo "MVM_UNSET: ${1}"
    echo "DECLARE OF ${1}:"
    declare -p "${1}" || :
    echo
    mvm_call "${1}" mvm_c_unset "${@:2}"
}

function mvm_c_unset() {
    local counter name extras_map_var_name storage_map_var_name destructor mvm_mcu_mvc_name

    counter=${mvm['counter']}
    name=${mvm['name']}
    extras_map_var_name=${mvm['extras']}
    storage_map_var_name=${mvm['storage']}
    destructor=${mvm['destructor']}

    while [[ ${counter} -gt 0 ]]; do
        counter=$((counter - 1))
        __mvm_mvc_name "${name}" "${counter}" mvm_mcu_mvc_name
        "${destructor}" "${mvm_mcu_mvc_name}"
    done
    unset "${storage_map_var_name}"
    unset "${extras_map_var_name}"
    unset "${name}"
}

function mvm_get_name() {
    mvm_call "${1}" mvm_c_get_name "${@:2}"
}

function mvm_c_get_name() {
    local name_var_name
    name_var_name=${1}; shift
    local -n name_ref="${name_var_name}"

    # shellcheck disable=SC2034 # it's a reference to external variable
    name_ref=${mvm['name']}
}

function mvm_get_extra() {
    mvm_call "${1}" mvm_c_get_extra "${@:2}"
}

function mvm_c_get_extra() {
    local extra extra_var_name
    extra=${1}; shift
    extra_var_name=${1}; shift
    local -n extra_ref="${extra_var_name}"

    local extras_map_var_name
    extras_map_var_name=${mvm['extras']}
    # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays
    local -n extras_map_ref="${extras_map_var_name}"

    # shellcheck disable=SC2034 # it's a reference to external variable
    extra_ref=${extras_map_ref["${extra}"]:-}
}

function mvm_get() {
    mvm_call "${1}" mvm_c_get "${@:2}"
}

function mvm_c_get() {
    local key value_var_name
    key=${1}; shift
    value_var_name=${1}; shift
    local -n value_ref="${value_var_name}"

    local storage_map_var_name
    storage_map_var_name=${mvm['storage']}
    # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays
    local -n storage_map_ref="${storage_map_var_name}"

    # shellcheck disable=SC2034 # it's a reference to external variable
    value_ref=${storage_map_ref["${key}"]:-}
}

function __mvm_c_make_new_mvc() {
    local key mvc_name_var_name
    key=${1}; shift
    mvc_name_var_name=${1}; shift

    local name counter storage_map_var_name
    name=${mvm['name']}
    counter=${mvm['counter']}
    storage_map_var_name=${mvm['storage']}
    # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays
    local -n storage_map_ref="${storage_map_var_name}"

    __mvm_mvc_name "${name}" "${counter}" "${mvc_name_var_name}"

    local constructor
    constructor=${mvm['constructor']}

    "${constructor}" "${!mvc_name_var_name}"
    mvm['counter']=$((counter + 1))
    storage_map_ref["${key}"]="${!mvc_name_var_name}"
}

function mvm_add() {
    mvm_call "${1}" mvm_c_add "${@:2}"
}

function mvm_c_add() {
    local key
    key=${1}; shift
    # rest are values to add

    local adder mvm_mca_mvc_name
    adder=${mvm['adder']}
    mvm_c_get "${key}" mvm_mca_mvc_name

    if [[ -z ${mvm_mca_mvc_name} ]]; then
        __mvm_c_make_new_mvc "${key}" mvm_mca_mvc_name
    fi
    "${adder}" "${mvm_mca_mvc_name}" "${@}"
}

function mvm_iterate() {
    mvm_call "${1}" mvm_c_iterate "${@:2}"
}

function mvm_c_iterate() {
    local callback
    callback=${1}; shift
    # rest are extra args passed to callback

    local storage_map_var_name helper
    storage_map_var_name=${mvm['storage']}
    # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays
    local -n storage_map_ref="${storage_map_var_name}"
    helper=${mvm['iteration_helper']}

    local key value
    if [[ -n "${helper}" ]]; then
        for key in "${!storage_map_ref[@]}"; do
            value=${storage_map_ref["${key}"]}
            "${helper}" "${key}" "${value}" "${callback}" "${@}"
        done
    else
        for key in "${!storage_map_ref[@]}"; do
            value=${storage_map_ref["${key}"]}
            "${callback}" "${@}" "${key}" "${value}"
        done
    fi
}

fi
