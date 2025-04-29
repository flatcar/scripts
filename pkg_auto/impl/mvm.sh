#!/bin/bash

#
# "mvm" stands for "multi-valued map", so these are maps of scalars
# (strings, numbers) to other container (arrays or maps)
#
# mvm is implemented with a map that contains some predefined keys,
# like "name", "constructor", "storage", etc.
#
# The "storage" field is the actual "map" part of the "mvm", at the
# values stored in it are names of the global variables being the
# "multi-valued" part of the "mvm". In the code these variables are
# referred to as "mvc" meaning "multi-value container".
#
# The "constructor" and "destructor" fields are here to properly
# implement creating and destroying mvcs. The "adder" field is for
# adding elements to an mvc.
#
# There is also a "counter" field which, together with the "name"
# field, is used for creating the names for mvc variables.
#
# The "extras" field is for user-defined mapping. The mvm will clear
# the mapping itself, but if the values are anything else than simple
# scalars (e.g. names of variables) then the cleanup of those is
# user's task.
#
# There is also an optional field named "iteration_helper" which is a
# callback invoked when iterating over the mvm.
#
# In order to implement a new mvc type, the following functions need
# to be implemented:
#
# <type>_constructor - takes an mvc name; should create an mvc with the
#                      passed name.
# <type>_destructor - takes an mvc name; should unset an mvc with the
#                     passed name, should likely take care of cleaning
#                     up the values stored in the mvc
# <type>_adder - takes an mvc name and values to be added; should add
#                the values to the mvc
# <type>_iteration_helper - optional; takes a key, an mvc name, a
#                           callback and extra arguments to be
#                           forwarded to the callback; should invoke
#                           the callback with the extra arguments, the
#                           key, the mvc name and optionally some
#                           extra arguments the helper deems useful

if [[ -z ${__MVM_SH_INCLUDED__:-} ]]; then
__MVM_SH_INCLUDED__=x

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

# Used for creating unique names for extras and storage maps.
MVM_COUNTER=0

# mvm API

# Creates a new mvm with a passed name, optionally type and
# extras. The name must be globally unique. The type is optional. If
# no type is passed, an array mvm will be assumed. Otherwise the type
# must be valid, i.e. it must provide a constructor, a destructor, an
# adder and, optionally, an iteration helper. The built in types are
# "mvm_mvc_array", "mvm_mvc_set" and "mvm_mvc_map". If any extras are
# passed, they must be preceded with a double dash to avoid ambiguity
# between type and a first extras key. Extras are expected to be even
# in count, odd elements will be used as keys, even elements will be
# used as values.
#
# Params:
#
# 1 - name of the mvm
# @ - optional mvc type, optionally followed by double dash and extras
#     key-value pairs.
function mvm_declare() {
    local mvm_var_name
    mvm_var_name=${1}; shift

    if declare -p "${mvm_var_name}" >/dev/null 2>/dev/null; then
        fail "variable ${mvm_var_name} already exists, declaring mvm for it would clobber it"
    fi

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

    mvm_debug "${mvm_var_name}" "using prefix ${value_handler_prefix}"

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
        mvm_debug "${mvm_var_name}" "no interation helper available"
        iteration_helper=''
    fi

    local extras_idx storage_idx extras_map_var_name storage_map_var_name
    extras_idx=$((MVM_COUNTER))
    storage_idx=$((MVM_COUNTER + 1))
    extras_map_var_name="mvm_stuff_${extras_idx}"
    storage_map_var_name="mvm_stuff_${storage_idx}"

    MVM_COUNTER=$((MVM_COUNTER + 2))

    declare -g -A "${mvm_var_name}" "${extras_map_var_name}" "${storage_map_var_name}"

    mvm_debug "${mvm_var_name}" "extras map: ${extras_map_var_name}, storage_map: ${storage_map_var_name}"

    local -n storage_map_ref=${storage_map_var_name}
    storage_map_ref=()

    local -n mvm_ref=${mvm_var_name}
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
    local -n extras_map_ref=${extras_map_var_name}
    while [[ ${#} -gt 1 ]]; do
        mvm_debug "${mvm_var_name}" "adding ${1} -> ${2} pair to extras"
        extras_map_ref["${1}"]=${2}
        shift 2
    done
    if [[ ${#} -gt 0 ]]; then
        fail "odd number of parameters for extra key value information for '${mvm_var_name}'"
    fi
}

# Takes a name of mvm, a callback, and extra parameters that will be
# forwarded to the callback. Before invoking the callback, the
# function will declare a local variable called "mvm" which is a
# reference to the variable with the passed name. The "mvm" variable
# can be used for easy access to the map within the callback.
#
# The convention is that the function foo_barize will use mvm_call to
# invoke a callback named foo_c_barize. The foo_c_barize function can
# invoke other _c_ infixed functions, like mvm_c_get_extra or
# mvm_c_get.
#
# Params:
#
# 1 - name of mvm variable
# 2 - name of the callback
# @ - arguments for the callback
function mvm_call() {
    local name func
    name=${1}; shift
    func=${1}; shift
    # rest are func args

    mvm_debug "${name}" "invoking ${func} with args: ${*@Q}"

    # The "mvm" variable can be used by ${func} now.
    local -n mvm=${name}
    "${func}" "${@}"
}

# Internal function that generates a name for mvc based on passed name
# and counter.
function __mvm_mvc_name() {
    local name counter mvc_name_var_name
    name=${1}; shift
    counter=${1}; shift
    mvc_name_var_name=${1}; shift
    local -n mvc_name_ref=${mvc_name_var_name}

    mvc_name_ref="mvm_${name}_mvc_${counter}"
}

# Destroy the mvm with passed name.
#
# Params:
#
# 1 - name of mvm to destroy
function mvm_unset() {
    mvm_call "${1}" mvm_c_unset "${@:2}"
}

# Helper function for mvm_unset invoked through mvm_call.
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

# Gets an value from extras map for a given key.
#
# Params:
#
# 1 - name of the mvm variable
# 2 - extra key
# 3 - name of a variable where the extra value will be stored
function mvm_get_extra() {
    mvm_call "${1}" mvm_c_get_extra "${@:2}"
}

# Helper function for mvm_get_extra invoked through mvm_call.
function mvm_c_get_extra() {
    local extra extra_var_name
    extra=${1}; shift
    extra_var_name=${1}; shift
    local -n extra_ref=${extra_var_name}

    local extras_map_var_name
    extras_map_var_name=${mvm['extras']}
    local -n extras_map_ref=${extras_map_var_name}

    extra_ref=${extras_map_ref["${extra}"]:-}
}

# Gets a name of the mvc for a given key.
#
# Params:
#
# 1 - name of the mvm variable
# 2 - key
# 3 - name of a variable where the mvc name will be stored
function mvm_get() {
    mvm_call "${1}" mvm_c_get "${@:2}"
}

# Helper function for mvm_get invoked through mvm_call.
function mvm_c_get() {
    local key value_var_name
    key=${1}; shift
    value_var_name=${1}; shift
    local -n value_ref=${value_var_name}

    local storage_map_var_name
    storage_map_var_name=${mvm['storage']}
    local -n storage_map_ref=${storage_map_var_name}

    value_ref=${storage_map_ref["${key}"]:-}
}

# Internal function for creating a new mvc.
function __mvm_c_make_new_mvc() {
    local key mvc_name_var_name
    key=${1}; shift
    mvc_name_var_name=${1}; shift

    local name counter storage_map_var_name
    name=${mvm['name']}
    counter=${mvm['counter']}
    storage_map_var_name=${mvm['storage']}
    local -n storage_map_ref=${storage_map_var_name}

    __mvm_mvc_name "${name}" "${counter}" "${mvc_name_var_name}"

    local constructor
    constructor=${mvm['constructor']}

    "${constructor}" "${!mvc_name_var_name}"
    mvm['counter']=$((counter + 1))
    storage_map_ref["${key}"]=${!mvc_name_var_name}
}

# Adds passed elements to the mvm under the given key. If an mvc for
# the key didn't exist in the mvm, it gets created.
#
# Params:
#
# 1 - name of the mvm variable
# 2 - key
# @ - elements
function mvm_add() {
    mvm_call "${1}" mvm_c_add "${@:2}"
}

# Helper function for mvm_add invoked through mvm_call.
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

# Removes the key from the mvm.
#
# Params:
#
# 1 - name of the mvm variable
# 2 - key
function mvm_remove() {
    mvm_call "${1}" mvm_c_remove "${@:2}"
}

# Helper function for mvm_remove invoked through mvm_call.
function mvm_c_remove() {
    local key
    key=${1}; shift

    local storage_map_var_name
    storage_map_var_name=${mvm['storage']}
    local -n storage_map_ref=${storage_map_var_name}

    if [[ -z ${storage_map_ref["${key}"]:-} ]]; then
        return 0
    fi

    local var_name=${storage_map_ref["${key}"]}
    unset "storage_map_ref[${key}]"

    local destructor
    destructor=${mvm['destructor']}

    "${destructor}" "${var_name}"
}

# Iterates over the key-mvc pairs and invokes a callback for each. The
# function also takes some extra parameters to forward to the
# callback. The callback will receive, in order, extra parameters, a
# key, an mvc name, and possibly some extra parameters from the
# iteration helper, if such exists for the mvm.
#
# Params:
#
# 1 - name of the mvm variable
# 2 - callback
# @ - extra parameters forwarded to the callback
function mvm_iterate() {
    mvm_call "${1}" mvm_c_iterate "${@:2}"
}

# Helper function for mvm_iterate invoked through mvm_call.
function mvm_c_iterate() {
    local callback
    callback=${1}; shift
    # rest are extra args passed to callback

    local storage_map_var_name helper
    storage_map_var_name=${mvm['storage']}
    local -n storage_map_ref=${storage_map_var_name}
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

# debugging

declare -A MVM_DEBUG_NAMES=()

# Enables printing debugging info for a specified mvm.
#
# Params:
#
# 1 - name of the mvm variable
function mvm_debug_enable() {
    local mvm_var_name=${1}; shift
    MVM_DEBUG_NAMES["${mvm_var_name}"]=x
}

# Print debugging info about the mvm if debugging for it was enabled
# beforehand.
#
# Params:
#
# 1 - name of the mvm variable
# @ - strings to be printed
function mvm_debug() {
    local name=${1}; shift

    if [[ -n ${MVM_DEBUG_NAMES["${name}"]:-} ]]; then
        info "MVM_DEBUG(${name}): ${*}"
    fi
}

# Disables printing debugging info for a specified mvm.
#
# Params:
#
# 1 - name of the mvm variable
function mvm_debug_disable() {
    local mvm_var_name=${1}; shift
    unset "MVM_DEBUG_NAMES[${mvm_var_name}]"
}

# Array mvm, the default. Provides an iteration helper that sends all
# the array values to the iteration callback.

function mvm_mvc_array_constructor() {
    local array_var_name
    array_var_name=${1}; shift

    declare -g -a "${array_var_name}"

    local -n array_ref=${array_var_name}
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
    local -n array_ref=${array_var_name}

    array_ref+=( "${@}" )
}

# iteration_helper is optional
function mvm_mvc_array_iteration_helper() {
    local key array_var_name callback
    key=${1}; shift
    array_var_name=${1}; shift
    callback=${1}; shift
    # rest are extra args passed to cb

    local -n array_ref=${array_var_name}
    "${callback}" "${@}" "${key}" "${array_var_name}" "${array_ref[@]}"
}

# Map mvm. When adding elements to the mvc, it is expected that the
# number of items passed will be even. Odd elements will be used as
# keys, even elements will be used as values.
#
# No iteration helper.

function mvm_mvc_map_constructor() {
    local map_var_name
    map_var_name=${1}; shift

    declare -g -A "${map_var_name}"

    local -n map_ref=${map_var_name}
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
    local -n map_ref=${map_var_name}

    while [[ ${#} -gt 1 ]]; do
        map_ref["${1}"]=${2}
        shift 2
    done
}

# Set mvm. Behaves like array mvm, but all elements in each set are
# unique and the order of elements is not guaranteed to be the same as
# order of insertions.

function mvm_mvc_set_constructor() {
    local set_var_name
    set_var_name=${1}; shift

    declare -g -A "${set_var_name}"

    local -n set_ref=${set_var_name}
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

    local -n set_ref=${set_var_name}
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

    local -n set_ref=${set_var_name}
    "${callback}" "${@}" "${key}" "${set_var_name}" "${!set_ref[@]}"
}

fi
