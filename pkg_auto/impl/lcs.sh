#!/bin/bash

if [[ -z ${__LCS_SH_INCLUDED__:-} ]]; then
__LCS_SH_INCLUDED__=x

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

declare -gri LCS_X1_IDX=0 LCS_X2_IDX=1 LCS_IDX1_IDX=2 LCS_IDX2_IDX=3

# Computes the longest common subsequence of two sequences and stores
# it in the passed array. The common items stored in the array with
# longest common subsequence are actually names of arrays, where each
# array stores an item from the first sequence, an item from the
# second sequence, an index of the first item in first sequence and an
# index of the second item in the second sequence.
#
# The function optionally takes a name of the equality function. If no
# such function is passed, the string equality is used. The function
# should take two parameters and should check them for equality; the
# parameters are items from the sequences passed to lcs_run; the
# function should return 0 (bash true value) if the items are equal,
# not 0 (bash false value) otherwise.
#
# Params:
#
# 1 - a name of an array variable containing the first sequence
# 2 - a name of an array variable containing the second sequence
# 3 - a name of an array variable where the longest common subsequence
#     will be stored
# 4 - optional, a name of an equality function
#
# Example:
#
# a=( A B C D E F G )
# b=( B C D G K )
# c=()
#
# lcs_run a b c
#
# echo "a: ${a[*]}"
# echo "b: ${b[*]}"
#
# cn=()
# for i in "${c[@]}"; do
#     declare -n ref=${i}
#     n=${ref[LCS_X1_IDX]}
#     unset -n ref
#     cn+=( "${n}" )
# done
# echo "c: ${cn[*]}"
# unset "${c[@]}"
function lcs_run() {
    local seq1_name=${1}; shift
    local seq2_name=${1}; shift
    local common_name=${1}; shift
    local eq_func=__lcs_str_eq
    if [[ ${#} -gt 0 ]]; then
        eq_func=${1}; shift
    fi

    if ! declare -pF "${eq_func}" >/dev/null 2>/dev/null; then
        fail "${eq_func@Q} is not a function"
    fi

    local -A lcs_memo_map=() lcs_memo_items_set=()
    local -a lr_lcs_state=( "${eq_func}" lcs_memo_map lcs_memo_items_set "${seq1_name}" "${seq2_name}" )

    local -n seq1=${seq1_name} seq2=${seq2_name}
    local -i idx1=$(( ${#seq1[@]} - 1 )) idx2=$(( ${#seq2[@]} - 1 ))

    __lcs_recurse lr_lcs_state "${idx1}" "${idx2}"

    local -n common_ref=${common_name}
    local lr_memo_key=''
    __lcs_make_memo_key "${idx1}" "${idx2}" lr_memo_key
    local -n memoized_items_ref=${lcs_memo_map["${lr_memo_key}"]}

    common_ref=( "${memoized_items_ref[@]}" )

    local item
    for item in "${common_ref[@]}"; do
        unset "lcs_memo_items_set[${item}]"
    done

    unset "${!lcs_memo_items_set[@]}"
    local items_var_name memo_key
    for memo_key in "${!memo_map_ref[@]}"; do
        items_var_name=${memo_map_ref["${memo_key}"]}
        if [[ ${items_var_name} != EMPTY_ARRAY ]]; then
            unset "${items_var_name}"
        fi
    done
}

##
## Details
##

declare -gri __LCS_EQ_IDX=0 __LCS_MEMO_MAP_IDX=1 __LCS_MEMO_ITEMS_SET_IDX=2 __LCS_SEQ1_IDX=3 __LCS_SEQ2_IDX=4

function __lcs_recurse() {
    local lcs_state_name=${1}; shift
    local -i i1=${1}; shift
    local -i i2=${1}; shift

    if [[ i1 -lt 0 || i2 -lt 0 ]]; then
        return 0
    fi

    local -n lcs_state=${lcs_state_name}

    local -n memo_map_ref=${lcs_state[__LCS_MEMO_MAP_IDX]}
    local memo_key=''
    __lcs_make_memo_key ${i1} ${i2} memo_key
    local seq_name=${memo_map_ref["${memo_key}"]:-}
    if [[ -n ${seq_name} ]]; then
        return 0
    fi
    unset seq_name memo_key
    unset -n memo_map_ref

    local -n seq1_ref=${lcs_state[__LCS_SEQ1_IDX]}
    local -n seq2_ref=${lcs_state[__LCS_SEQ2_IDX]}
    local x1=${seq1_ref[i1]}
    local x2=${seq2_ref[i2]}
    unset -n seq2_ref seq1_ref

    local equal=x
    local eq_func=${lcs_state[__LCS_EQ_IDX]}
    "${eq_func}" "${x1}" "${x2}" || equal=''
    unset eq_func

    if [[ -n "${equal}" ]]; then
        __lcs_recurse "${lcs_state_name}" $((i1 - 1)) $((i2 - 1))

        local n
        gen_varname lcs_common n

        declare -a -g "${n}=()"

        # retrieve memoized result for i1-1 and i2-1 (what we just
        # called above), make a copy of it, add the prepared item and
        # memoize that copy for i1 and i2; also add the prepared item
        # to the set of prepared items
        local -n memo_map_ref=${lcs_state[__LCS_MEMO_MAP_IDX]}
        local previous_memo_key
        __lcs_make_memo_key $((i1 - 1)) $((i2 - 1)) previous_memo_key
        local -n previous_memoized_prepared_items_ref=${memo_map_ref["${previous_memo_key}"]:-EMPTY_ARRAY}
        local -n c=${n}
        local prepared_item_to_insert

        gen_varname prepared_item_to_insert
        declare -g -a "${prepared_item_to_insert}=( ${x1@Q} ${x2@Q} ${i1@Q} ${i2@Q} )"

        c=( "${previous_memoized_prepared_items_ref[@]}" "${prepared_item_to_insert}" )

        local memo_key
        __lcs_make_memo_key ${i1} ${i2} memo_key
        memo_map_ref["${memo_key}"]=${n}

        local -n memo_items_set=${lcs_state[__LCS_MEMO_ITEMS_SET_IDX]}
        # shellcheck disable=SC2034 # shellcheck does not grok references
        memo_items_set["${prepared_item_to_insert}"]=x
    else
        __lcs_recurse "${lcs_state_name}" ${i1} $((i2 - 1))
        __lcs_recurse "${lcs_state_name}" $((i1 - 1)) ${i2}

        # retrieve memoized results for i1 and i2-1 and for i1-1 and
        # i2 (what we just called above), and memoize the longer
        # result for i1 and i2
        #
        # shellcheck disable=SC2178 # shellcheck does not grok references
        local -n memo_map_ref=${lcs_state[__LCS_MEMO_MAP_IDX]}
        local previous_memo_key=''
        __lcs_make_memo_key ${i1} $((i2 - 1)) previous_memo_key
        local previous_memoized_prepared_items_name1=${memo_map_ref["${previous_memo_key}"]:-EMPTY_ARRAY}
        local -n previous_memoized_prepared_items_ref1=${previous_memoized_prepared_items_name1}

        previous_memo_key=''
        __lcs_make_memo_key $((i1 - 1)) ${i2} previous_memo_key
        local previous_memoized_prepared_items_name2=${memo_map_ref["${previous_memo_key}"]:-EMPTY_ARRAY}
        local -n previous_memoized_prepared_items_ref2=${previous_memoized_prepared_items_name2}

        local memo_key=''
        __lcs_make_memo_key ${i1} ${i2} memo_key
        if [[ ${#previous_memoized_prepared_items_ref1[@]} -gt ${#previous_memoized_prepared_items_ref2[@]} ]]; then
            memo_map_ref["${memo_key}"]=${previous_memoized_prepared_items_name1}
        else
            memo_map_ref["${memo_key}"]=${previous_memoized_prepared_items_name2}
        fi
    fi
}

function __lcs_make_memo_key() {
    local i1=${1}; shift
    local i2=${1}; shift
    local -n ref=${1}; shift
    local key="x${i1}x${i2}x"
    key=${key//-/_}
    ref=${key}
}

function __lcs_str_eq() {
    [[ "${1}" = "${2}" ]]
}

fi
