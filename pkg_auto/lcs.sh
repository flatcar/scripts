#!/bin/bash

# set -x
set -euo pipefail

# takes a function prefix and a name of a variable, which will contain
# a name of a variable having a state for subsequent lcs_run function
#
# it is expected that for given prefix, functions ${prefix}_eq,
# ${prefix}_prep and ${prefix}_kill will be defined
#
# ${prefix}_eq takes two parameters and checks them for equality; the
# parameters are items from the sequences passed to lcs_run; the
# function should return 0 if the items are equal, not 0 otherwise
#
# ${prefix}_prep takes five parameters: item from first sequence, item
# from second sequence, index of the first item in the first sequence,
# index of the second item in the second sequence and a name of a
# variable where the prepared item will be stored; the function should
# create a prepared item which will be stored in the longest common
# subsequence
#
# ${prefix}_kill takes multiple parameters, all of them being prepared
# items that should be unset
function lcs_setup() {
    local func_prefix=${1}; shift
    local -n lcs_var_name_ref=${1}; shift

    local lcs_name=lcs_setup_${__LCS_COUNTER}
    __LCS_COUNTER=$((__LCS_COUNTER + 1))

    local eq_func=${func_prefix}_eq prep_func=${func_prefix}_prep kill_func=${func_prefix}_kill
    local func
    for func in "${eq_func}" "${prep_func}" "${kill_func}"; do
        if ! declare -pF "${func}" >/dev/null 2>/dev/null; then
            fail "${func@Q} is not a function, is ${func_prefix@Q} a valid prefix?"
        fi
    done

    declare -g -a "${lcs_name}"
    local -n lcs=${lcs_name}

    # shellcheck disable=SC2034 # it's a reference to a global
    # variable declared just above
    lcs=( "${eq_func}" "${prep_func}" "${kill_func}" )

    # shellcheck disable=SC2034 # same as above
    lcs_var_name_ref=${lcs_name}
}

# takes a name of a variable containing the state, a name of an array
# variable containing the first sequence, a name of a variable
# containing the second sequence and a name of a variable where the
# longest common subsequence will be stored
function lcs_run() {
    local lcs_name=${1}; shift
    local seq1_name=${1}; shift
    local seq2_name=${1}; shift
    local common_name=${1}; shift

    local -n lcs_ref=${lcs_name}

    # rt - runtime
    local -a lr_lcs_rt=( "${lcs_ref[@]}" )
    local lcs_rt_memo_map_name=lcs_rt_memo_map_$((__LCS_COUNTER + 1))
    local lcs_rt_memo_items_set_name=lcs_rt_memo_items_set_$((__LCS_COUNTER + 2))
    local -A "${lcs_rt_memo_map_name}=()" "${lcs_rt_memo_items_set_name}=()"

    __LCS_COUNTER=$((__LCS_COUNTER + 2))

    lr_lcs_rt+=( "${lcs_rt_memo_map_name}" "${lcs_rt_memo_items_set_name}" "${seq1_name}" "${seq2_name}" )

    local -n seq1=${seq1_name} seq2=${seq2_name}
    local idx1=$(( ${#seq1[@]} - 1 )) idx2=$(( ${#seq2[@]} - 1 ))

    __lcs_recurse lr_lcs_rt "${idx1}" "${idx2}"

    local -n common_ref=${common_name} items_set_ref=${lcs_rt_memo_items_set_name} memo_map_ref=${lcs_rt_memo_map_name}
    local memo_key=''
    __lcs_make_memo_key "${idx1}" "${idx2}" memo_key
    local -n memoized_items_ref=${memo_map_ref["${memo_key}"]}

    common_ref=( "${memoized_items_ref[@]}" )

    local item
    for item in "${common_ref[@]}"; do
        unset "items_set[${item}]"
    done

    local kill_func=${lr_lcs_rt["${__LCS_KILL_IDX}"]}
    if [[ ${#items_set_ref[@]} -gt 0 ]]; then
        "${kill_func}" "${!items_set_ref[@]}"
    fi
    local items_var_name
    for memo_key in "${!memo_map_ref[@]}"; do
        items_var_name=${memo_map_ref["${memo_key}"]}
        if [[ ${items_var_name} != __LCS_EMPTY_ARRAY ]]; then
            unset "${items_var_name}"
        fi
    done
}

declare -gi __LCS_COUNTER=1

declare -ri __LCS_EQ_IDX=0 __LCS_PREP_IDX=1 __LCS_KILL_IDX=2
# used during lcs_run only
declare -ri __LCS_MEMO_MAP_IDX=3 __LCS_MEMO_ITEMS_SET_IDX=4 __LCS_SEQ1_IDX=5 __LCS_SEQ2_IDX=6

declare -ra __LCS_EMPTY_ARRAY=()

function __lcs_recurse() {
    local lcs_rt_name=${1}; shift
    local i1=${1}; shift
    local i2=${1}; shift

    if [[ ${i1} -lt 0 || ${i2} -lt 0 ]]; then
        return 0
    fi

    local -n lcs_rt=${lcs_rt_name}

    local -n memo_map_ref=${lcs_rt["${__LCS_MEMO_MAP_IDX}"]}
    local memo_key=''
    __lcs_make_memo_key "${i1}" "${i2}" memo_key
    local seq_name=${memo_map_ref["${memo_key}"]:-}
    if [[ -n ${seq_name} ]]; then
        return 0
    fi
    unset seq_name memo_key
    unset -n memo_map_ref

    local -n seq1=${lcs_rt["${__LCS_SEQ1_IDX}"]}
    local -n seq2=${lcs_rt["${__LCS_SEQ2_IDX}"]}
    local x1=${seq1["${i1}"]}
    local x2=${seq2["${i2}"]}
    unset -n seq2 seq1

    local equal=x
    local eq_func=${lcs_rt["${__LCS_EQ_IDX}"]}
    "${eq_func}" "${x1}" "${x2}" || equal=''
    unset eq_func

    if [[ -n "${equal}" ]]; then
        __lcs_recurse "${lcs_rt_name}" $((i1 - 1)) $((i2 - 1))

        local n=common${__LCS_COUNTER}
        __LCS_COUNTER=$((__LCS_COUNTER + 1))

        declare -a -g "${n}=()"

        # retrieve memoized result for i1-1 and i2-1 (what we just
        # called above), make a copy of it, add the prepared item and
        # memoize that copy for i1 and i2; also add the prepared item
        # to the set of prepared items
        local -n memo_map_ref=${lcs_rt["${__LCS_MEMO_MAP_IDX}"]}
        local previous_memo_key=''
        __lcs_make_memo_key "$((i1 - 1))" "$((i2 - 1))" previous_memo_key
        local -n previous_memoized_prepared_items_ref=${memo_map_ref["${previous_memo_key}"]:-__LCS_EMPTY_ARRAY}
        local -n c=${n}
        local prepared_item_to_insert='NONE' prep_func=${lcs_rt["${__LCS_PREP_IDX}"]}
        "${prep_func}" "${x1}" "${x2}" "${i1}" "${i2}" prepared_item_to_insert
        c=( "${previous_memoized_prepared_items_ref[@]}" "${prepared_item_to_insert}" )

        local memo_key="x${i1}x${i2}x"
        __lcs_make_memo_key "${i1}" "${i2}" memo_key
        memo_map_ref["${memo_key}"]=${n}

        local -n memo_items_set=${lcs_rt["${__LCS_MEMO_ITEMS_SET_IDX}"]}
        # shellcheck disable=SC2034 # shellcheck does not grok references
        memo_items_set["${prepared_item_to_insert}"]=x
    else
        __lcs_recurse "${lcs_rt_name}" "${i1}" $((i2 - 1))
        __lcs_recurse "${lcs_rt_name}" $((i1 - 1)) "${i2}"

        # retrieve memoized results for i1 and i2-1 and for i1-1 and
        # i2 (what we just called above), and memoize the longer
        # result for i1 and i2
        #
        # shellcheck disable=SC2178 # shellcheck does not grok references
        local -n memo_map_ref=${lcs_rt["${__LCS_MEMO_MAP_IDX}"]}
        local previous_memo_key=''
        __lcs_make_memo_key "${i1}" "$((i2 - 1))" previous_memo_key
        local previous_memoized_prepared_items_name1=${memo_map_ref["${previous_memo_key}"]:-__LCS_EMPTY_ARRAY}
        local -n previous_memoized_prepared_items_ref1=${previous_memoized_prepared_items_name1}

        previous_memo_key=''
        __lcs_make_memo_key "$((i1 - 1))" "${i2}" previous_memo_key
        local previous_memoized_prepared_items_name2=${memo_map_ref["${previous_memo_key}"]:-__LCS_EMPTY_ARRAY}
        local -n previous_memoized_prepared_items_ref2=${previous_memoized_prepared_items_name2}

        local memo_key=''
        __lcs_make_memo_key "${i1}" "${i2}" memo_key
        local kill_func=${lcs_rt["${__LCS_KILL_IDX}"]}
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

##
##
##

# takes two items, compares them, returns true if equal, false
# otherwise
function simple_eq() {
    [[ "${1}" = "${2}" ]]
}

# takes two items that compared equal, two indices (where in both
# sequences those items are) and a name of the variable where the
# prepared item to be stored in common array should be placed
function simple_prep() {
    local item=${1}; shift 4; local -n ref=${1}; shift
    # shellcheck disable=SC2034 # shellcheck does not grok references
    ref=${item}
}

# takes all prepared items that should be unset
function simple_kill() {
    :
}

a=( A B C D E F G )
b=( B C D G K )
c=()

test_lcs_name=''

lcs_setup simple test_lcs_name
lcs_run "${test_lcs_name}" a b c

echo "a: ${a[*]}"
echo "b: ${b[*]}"
echo "c: ${c[*]}"
