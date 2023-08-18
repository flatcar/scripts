#!/bin/bash

MVM_COUNTER=0

# array mvm, default
function mvm_mvc_array_constructor() {
    declare -g -a "${1}"

    local -n mvm_mmac_array="${1}"
    mvm_mmac_array=()
}

function mvm_mvc_array_destructor() {
    unset "${1}"
}

function mvm_mvc_array_adder() {
    local -n mvm_mmaa_array_var="${1}"; shift
    mvm_mmaa_array_var+=( "${@}" )
}

# iteration_helper is optional
function mvm_mvc_array_iteration_helper() {
    local k v cb

    k=${1}; shift
    v=${1}; shift
    cb=${1}; shift
    # rest are extra args passed to cb

    local -n mvm_mmaih_array_var="${v}"
    "${cb}" "${@}" "${k}" "${v}" "${mvm_mmaih_array_var[@]}"
}

# map mvm
function mvm_mvc_map_constructor() {
    declare -g -A "${1}=()"

    local -n mvm_mmmc_map="${1}"
    mvm_mmmc_map=()
}

function mvm_mvc_map_destructor() {
    unset "${1}"
}

function mvm_mvc_map_adder() {
    local -n mvm_mmma_map_var="${1}"; shift
    while [[ ${#} -gt 1 ]]; do
        mvm_mmma_map_var["${1}"]=${2}
        shift 2
    done
}

# set mvm
function mvm_mvc_set_constructor() {
    declare -g -A "${1}"

    local -n mvm_mmsc_set="${1}"
    mvm_mmsc_set=()
}

function mvm_mvc_set_destructor() {
    unset "${1}"
}

function mvm_mvc_set_adder() {
    local -n mvm_mmsa_set_var="${1}"; shift
    while [[ ${#} -gt 0 ]]; do
        mvm_mmsa_set_var["${1}"]=x
        shift
    done
}

# iteration_helper is optional
function mvm_mvc_set_iteration_helper() {
    local k v cb

    k=${1}; shift
    v=${1}; shift
    cb=${1}; shift
    # rest are extra args passed to cb

    local -n mvm_mmsih_set_var="${v}"
    "${cb}" "${@}" "${k}" "${v}" "${!mvm_mmsih_set_var[@]}"
}

# mvm functions
function mvm_declare() {
    local name value_handler_prefix constructor destructor adder iteration_helper func extras_idx storage_idx extras_name storage_name

    name=${1}; shift
    if [[ -n ${1:-} ]] && [[ ${1} != '--' ]]; then
        value_handler_prefix=${1}
        shift
    else
        value_handler_prefix=mvm_mvc_array
    fi
    shift
    constructor="${value_handler_prefix}_constructor"
    destructor="${value_handler_prefix}_destructor"
    adder="${value_handler_prefix}_adder"
    iteration_helper="${value_handler_prefix}_iteration_helper"

    for func in "${constructor}" "${destructor}" "${adder}"; do
        if ! declare -pF "${func}" >/dev/null 2>/dev/null; then
            fail "'${func}' is not a function"
        fi
    done

    if ! declare -pF "${iteration_helper}" >/dev/null 2>/dev/null; then
        iteration_helper=''
    fi

    # rest is extras - pairs of keys and values
    extras_idx=$((MVM_COUNTER))
    storage_idx=$((MVM_COUNTER + 1))
    extras_name="mvm_stuff_${extras_idx}"
    storage_name="mvm_stuff_${storage_idx}"

    MVM_COUNTER=$((MVM_COUNTER + 2))

    declare -g -A "${name}" "${extras_name}"=() "${storage_name}"=()

    local -n mvm="${name}"
    mvm=(
        ['name']="${name}"
        ['constructor']="${constructor}"
        ['destructor']="${destructor}"
        ['adder']="${adder}"
        ['iteration_helper']="${iteration_helper}"
        ['counter']=0
        ['extras']="mvm_stuff_${extras_idx}"
        ['storage']="mvm_stuff_${storage_idx}"
    )
    local -n extras="${extras_name}"
    while [[ ${#} -gt 1 ]]; do
        extras["${1}"]=${2}
        shift 2
    done
    if [[ ${#} -gt 0 ]]; then
        fail "odd number of parameters for extra key value information for '${name}'"
    fi
}

function mvm_call() {
    local name=${1}; shift
    local func=${1}; shift
    # rest are func args

    local -n mvm="${name}"
    "${func}" "${@}"
}

function __mvm_element_name() {
    local name counter mvm_man_element_name_var_name

    name=${1}; shift
    counter=${1}; shift
    mvm_man_element_name_var_name=${1}; shift
    local -n mvm_man_element_name_var="${mvm_man_element_name_var_name}"

    mvm_man_element_name_var="mvm_${name}_element_${counter}"
}

function mvm_unset() {
    mvm_call "${1}" mvm_c_unset "${@:2}"
}

function mvm_c_unset() {
    local counter name extras_name storage_name destructor element_name

    counter=${mvm['counter']}
    name=${mvm['name']}
    extras_name=${mvm['extras']}
    storage_name=${mvm['storage']}
    destructor=${mvm['destructor']}

    while [[ ${counter} -gt 0 ]]; do
        counter=$((counter - 1))
        __mvm_element_name "${name}" "${counter}" element_name
        "${destructor}" "${element_name}"
    done
    unset "${storage_name}"
    unset "${extras_name}"
    unset "${name}"
}

function mvm_get_name() {
    mvm_call "${1}" mvm_c_get_name "${@:2}"
}

function mvm_c_get_name() {
    local mvm_mcgn_name_var_name

    mvm_mcgn_name_var_name=${1}; shift
    local -n mvm_mcgn_name_var="${mvm_mcgn_name_var_name}"

    mvm_mcgn_name_var=${mvm['name']}
}

function mvm_get_extra() {
    mvm_call "${1}" mvm_c_get_extra "${@:2}"
}

function mvm_c_get_extra() {
    local extra mvm_mcge_extra_var_name mvm_mcge_extras_name

    extra=${1}; shift
    mvm_mcge_extra_var_name=${1}; shift
    local -n mvm_mcge_extra_var="${mvm_mcge_extra_var_name}"
    mvm_mcge_extras_name=${mvm['extras']}
    local -n mvm_mcge_extras="${mvm_mcge_extras_name}"

    mvm_mcge_extra_var=${mvm_mcge_extras["${extra}"]:-}
}

function mvm_get() {
    mvm_call "${1}" mvm_c_get "${@:2}"
}

function mvm_c_get() {
    local k mvm_mcg_v_var_name mvm_mcg_mvm_storage_name

    k=${1}; shift
    mvm_mcg_v_var_name=${1}; shift
    local -n mvm_mcg_v_var="${mvm_mcg_v_var_name}"
    mvm_mcg_mvm_storage_name=${mvm['storage']}
    local -n mvm_mcg_mvm_storage="${mvm_mcg_mvm_storage_name}"

    mvm_mcg_v_var=${mvm_mcg_mvm_storage["${k}"]:-}
}

function __mvm_c_make_new_element() {
    local k mvm_mcmna_element_name_var_name name counter mvm_mcmna_storage_name mvm_mcmna_storage constructor

    k=${1}; shift
    mvm_mcmna_element_name_var_name=${1}; shift
    name=${mvm['name']}
    counter=${mvm['counter']}
    mvm_mcmna_storage_name=${mvm['storage']}
    local -n mvm_mcmna_storage="${storage_name}"

    __mvm_element_name "${name}" "${counter}" "${mvm_mcmna_element_name_var_name}"

    constructor=${mvm['constructor']}
    "${constructor}" "${!mvm_mcmna_element_name_var_name}"
    mvm['counter']=$((counter + 1))
    mvm_mcmna_storage["${pkg}"]="${!mvm_mcmna_element_name_var_name}"
}

function mvm_add() {
    mvm_call "${1}" mvm_c_add "${@:2}"
}

function mvm_c_add() {
    local k adder mvm_mca_element_name

    k=${1}; shift
    # rest are values to add
    adder=${mvm['adder']}
    mvm_c_get "${k}" mvm_mca_element_name

    if [[ -z ${mvm_mca_element_name} ]]; then
        __mvm_c_make_new_element "${k}" mvm_mca_element_name
    fi
    "${adder}" "${mvm_mca_element_name}" "${@}"
}

function mvm_iterate() {
    mvm_call "${1}" mvm_c_iterate "${@:2}"
}

function mvm_c_iterate() {
    local callback mvm_mci_storage_name helper k v

    callback=${1}; shift
    # rest are extra args passed to callback
    mvm_mci_storage_name=${mvm['storage']}
    helper=${mvm['iteration_helper']}
    local -n mvm_mci_storage="${mvm_mci_storage_name}"

    if [[ -n "${helper}" ]]; then
        for k in "${!mvm_mci_storage[@]}"; do
            v=${mvm_mci_storage["${k}"]}
            "${helper}" "${k}" "${v}" "${callback}" "${@}"
        done
    else
        for k in "${!mvm_mci_storage[@]}"; do
            v=${mvm_mci_storage["${k}"]}
            "${callback}" "${@}" "${k}" "${v}"
        done
    fi
}

# TODO: works only for arrays
#
# function mvm_merge() {
#     local m1_name m2_name
#
#     m1_name=${1}
#     m2_name=${2}
#
#     mvm_iterate "${m2_name}" mvm_merge_helper "${m1_name}"
# }
#
# function mvm_merge_helper() {
#     local target k
#
#     target=${1}; shift
#     k=${1}; shift
#     shift # we don't need the array name
#     # rest are values
#     mvm_add "${target}" "${k}" "${@}"
# }
