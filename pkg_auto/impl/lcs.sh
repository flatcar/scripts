#!/bin/bash

# Implementation of longest common subsequence (LCS) algorithm, with
# memoization and scoring. The algorithm is a base of utilities like
# diff - it finds the common items in two sequences.
#
# The memoization part is about remembering the results of LCS
# computation for shorter sequences, so they can be reused when doing
# computation for longer sequences.
#
# The scoring part is about generalization of the comparison function,
# which normally would return a boolean value describing whether two
# items are equal or not. With scoring, two things change. First is
# that the returned value from the comparison/scoring function is not
# a boolean, but rather an integer describing the degree of equality
# of the items. And second is that with booleans, the winning
# subsequence was the longest one, but with scores is not necessarily
# the longest one, but with the highest total score. This changes the
# algorithm a bit. While the typical LCS algorithm goes like as
# follows (s1 and s2 are sequences, i1 and i2 are indices in their
# respective sequences):
#
#
#
# LCS(s1, s2, i1, i2) -> sequence:
#   if (i1 >= len(s1) || i2 >= len(s2)): return ()
#   if (s1[i1] == s2[i2]):
#     l = LCS(s1, s2, i1 + 1, i2 + 1)
#     return (s1[i1], l...)
#   else:
#     l1 = LCS(s1, s2, i1 + 1, i2)
#     l2 = LCS(s1, s2, i1, i2 + 1)
#     if (len(l1) > len(l2)): return l1
#     return l2
#
#
#
# The score LCS goes more or less like this:
#
#
#
# SLCS(s1, s2, i1, i2) -> tuple(score, sequence):
#   if (i1 >= len(s1) || i2 >= len(21)): return (score: 0, sequence: ())
#   score = score_func(s1[i1], s2[i2])
#   if (score == max_score):
#     # matches the "equal" case in LCS above
#     l = SLCS(s1, s2, i1 + 1, i2 + 1)
#     return (score: score + l.score, sequence: (s1[i1], l.sequence...)
#   else if (score == 0):
#     # matches the "not equal" case in LCS above
#     l1 = SLCS(s1, s2, i1 + 1, i2)
#     l2 = SLCS(s1, s2, i1, i2 + 1)
#     if (l1.score > l2.score): return l1
#     return l2
#   else:
#     # new "equal, but not quite" case
#     l = SLCS(s1, s2, i1 + 1, i2 + 1)
#     l.score = score + l.score
#     l.sequence = (s1[i1], l.sequence...)
#     l1 = SLCS(s1, s2, i1 + 1, i2)
#     l2 = SLCS(s1, s2, i1, i2 + 1)
#     return tuple_with_max_score(l, l1, l2)
#
#
#
# The difference in the implementation below is that instead of
# starting at index 0 and go up for each sequence, we start at max
# index and go down.

if [[ -z ${__LCS_SH_INCLUDED__:-} ]]; then
__LCS_SH_INCLUDED__=x

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

# Constants to use for accessing fields in common items.
declare -gri LCS_X1_IDX=0 LCS_X2_IDX=1 LCS_IDX1_IDX=2 LCS_IDX2_IDX=3

# Computes the longest common subsequence of two sequences and stores
# it in the passed array. The common items stored in the array with
# longest common subsequence are actually names of arrays, where each
# array stores an item from the first sequence, an item from the
# second sequence, an index of the first item in first sequence and an
# index of the second item in the second sequence. To access those
# fields, use the LCS_*_IDX constants.
#
# The function optionally takes a name of the score function. If no
# such function is passed, the simple string score function is used
# (gives score 1 if strings are equal, otherwise gives score 0). The
# function should take either one or three parameters. The first
# parameter is always a name of a score integer variable. If only one
# parameter is passed, the function should write the maximum score to
# the score variable. When three parameters are passed, then the
# second and third are items from the sequences passed to lcs_run and
# they should be compared and rated. The function should rate the
# items with zero if they are completely different, with max score if
# they are the same, and with something in between zero and max score
# if they are somewhat equal but not really.
#
# Params:
#
# 1 - a name of an array variable containing the first sequence
# 2 - a name of an array variable containing the second sequence
# 3 - a name of an array variable where the longest common subsequence
#     will be stored
# 4 - optional, a name of a score function
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
    local score_func=__lcs_str_score
    if [[ ${#} -gt 0 ]]; then
        score_func=${1}; shift
    fi

    if ! declare -pF "${score_func}" >/dev/null 2>/dev/null; then
        fail "${score_func@Q} is not a function"
    fi

    local -i lr_max_score
    "${score_func}" lr_max_score

    # lcs_memo_items_set is a set of common item names; the set owns
    # the common items
    #
    # lcs_memo_map is a mapping from a memo key (which encodes indices
    # from both sequences) to a pair, being a score and a name of an
    # longest common subsequence for the encoded indices, separated
    # with semicolon
    local -A lcs_memo_map=() lcs_memo_items_set=()
    local -a lr_lcs_state=( "${score_func}" lcs_memo_map lcs_memo_items_set "${seq1_name}" "${seq2_name}" "${lr_max_score}" )

    local -n seq1=${seq1_name} seq2=${seq2_name}
    local -i idx1=$(( ${#seq1[@]} - 1 )) idx2=$(( ${#seq2[@]} - 1 ))
    unset -n seq1 seq2

    __lcs_recurse lr_lcs_state "${idx1}" "${idx2}"

    local -n common_ref=${common_name}
    local lr_memo_key=''
    __lcs_make_memo_key "${idx1}" "${idx2}" lr_memo_key
    local pair=${lcs_memo_map["${lr_memo_key}"]}
    local -n memoized_items_ref=${pair#*:}

    common_ref=( "${memoized_items_ref[@]}" )

    # steal the items from the items set that are a part of desired
    # LCS, so they are not freed now, but later, when the LCS is freed
    local item
    for item in "${common_ref[@]}"; do
        unset "lcs_memo_items_set[${item}]"
    done

    # free the unneeded items
    unset "${!lcs_memo_items_set[@]}"
    # free all the LCSes, we already have a copy of the one we wanted
    local items_var_name memo_key
    for memo_key in "${!lcs_memo_map[@]}"; do
        pair=${lcs_memo_map["${memo_key}"]}
        items_var_name=${pair#*:}
        if [[ ${items_var_name} != EMPTY_ARRAY ]]; then
            unset "${items_var_name}"
        fi
    done
}

##
## Details
##

declare -gri __LCS_SCORE_IDX=0 __LCS_MEMO_MAP_IDX=1 __LCS_MEMO_ITEMS_SET_IDX=2 __LCS_SEQ1_IDX=3 __LCS_SEQ2_IDX=4 __LCS_MAX_SCORE_IDX=5

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
    local pair=${memo_map_ref["${memo_key}"]:-}
    if [[ -n ${pair} ]]; then
        return 0
    fi
    unset pair memo_key
    unset -n memo_map_ref

    local -n seq1_ref=${lcs_state[__LCS_SEQ1_IDX]}
    local -n seq2_ref=${lcs_state[__LCS_SEQ2_IDX]}
    local x1=${seq1_ref[i1]}
    local x2=${seq2_ref[i2]}
    unset -n seq2_ref seq1_ref

    local -i lr_diff_score
    local score_func=${lcs_state[__LCS_SCORE_IDX]}
    "${score_func}" lr_diff_score "${x1}" "${x2}"
    unset score_func

    local -i max_score=${lcs_state[__LCS_MAX_SCORE_IDX]}
    if [[ lr_diff_score -gt max_score ]]; then
        lr_diff_score=max_score
    fi
    if [[ lr_diff_score -lt 0 ]]; then
        lr_diff_score=0
    fi

    if [[ lr_diff_score -eq max_score ]]; then
        unset max_score

        __lcs_recurse "${lcs_state_name}" $((i1 - 1)) $((i2 - 1))

        local n
        gen_varname __LCS_COMMON n

        declare -a -g "${n}=()"

        # retrieve memoized result for i1-1 and i2-1 (what we just
        # called above), make a copy of it, add the prepared item and
        # memoize that copy for i1 and i2; also add the prepared item
        # to the set of prepared items
        local -n memo_map_ref=${lcs_state[__LCS_MEMO_MAP_IDX]}
        local previous_memo_key
        __lcs_make_memo_key $((i1 - 1)) $((i2 - 1)) previous_memo_key
        local previous_pair=${memo_map_ref["${previous_memo_key}"]:-'0:EMPTY_ARRAY'}
        local previous_score=${previous_pair%%:*}
        local -n previous_memoized_prepared_items_ref=${previous_pair#*:}
        local -n c_ref=${n}
        local prepared_item_to_insert

        gen_varname __LCS_PREP prepared_item_to_insert
        declare -g -a "${prepared_item_to_insert}=( ${x1@Q} ${x2@Q} ${i1@Q} ${i2@Q} )"

        c_ref=( "${previous_memoized_prepared_items_ref[@]}" "${prepared_item_to_insert}" )

        local memo_key
        __lcs_make_memo_key ${i1} ${i2} memo_key
        memo_map_ref["${memo_key}"]="$((lr_diff_score + previous_score)):${n}"

        local -n memo_items_set=${lcs_state[__LCS_MEMO_ITEMS_SET_IDX]}
        memo_items_set["${prepared_item_to_insert}"]=x
    elif [[ lr_diff_score -eq 0 ]]; then
        unset max_score

        __lcs_recurse "${lcs_state_name}" ${i1} $((i2 - 1))
        __lcs_recurse "${lcs_state_name}" $((i1 - 1)) ${i2}

        # retrieve memoized results for i1 and i2-1 and for i1-1 and
        # i2 (what we just called above), and memoize the longer
        # result for i1 and i2
        local -n memo_map_ref=${lcs_state[__LCS_MEMO_MAP_IDX]}
        local lr_memo_key=''

        __lcs_make_memo_key ${i1} $((i2 - 1)) lr_memo_key
        local previous_pair1=${memo_map_ref["${lr_memo_key}"]:-'0:EMPTY_ARRAY'}
        local -i previous_score1=${previous_pair1%%:*}

        __lcs_make_memo_key $((i1 - 1)) ${i2} lr_memo_key
        local previous_pair2=${memo_map_ref["${lr_memo_key}"]:-'0:EMPTY_ARRAY'}
        local -i previous_score2=${previous_pair2%%:*}

        __lcs_make_memo_key ${i1} ${i2} lr_memo_key
        if [[ previous_score1 -gt previous_score2 ]]; then
            memo_map_ref["${lr_memo_key}"]=${previous_pair1}
        else
            memo_map_ref["${lr_memo_key}"]=${previous_pair2}
        fi
    else
        unset max_score

        # 1
        __lcs_recurse "${lcs_state_name}" $((i1 - 1)) $((i2 - 1))
        # 2
        __lcs_recurse "${lcs_state_name}" ${i1} $((i2 - 1))
        # 3
        __lcs_recurse "${lcs_state_name}" $((i1 - 1)) ${i2}

        local lr_mk1 lr_mk2 lr_mk3
        __lcs_make_memo_key $((i1 - 1)) $((i2 - 1)) lr_mk1
        __lcs_make_memo_key ${i1} $((i2 - 1)) lr_mk2
        __lcs_make_memo_key $((i1 - 1)) ${i2} lr_mk3

        local -n memo_map_ref=${lcs_state[__LCS_MEMO_MAP_IDX]}
        local pair1=${memo_map_ref["${lr_mk1}"]:-'0:EMPTY_ARRAY'}
        local pair2=${memo_map_ref["${lr_mk2}"]:-'0:EMPTY_ARRAY'}
        local pair3=${memo_map_ref["${lr_mk3}"]:-'0:EMPTY_ARRAY'}
        local -i score1=${pair1%%:*}
        local -i score2=${pair2%%:*}
        local -i score3=${pair3%%:*}
        local -i pick # either 1, 2 or 3
        score1=$((score1 + lr_diff_score))

        if [[ score1 -gt score2 ]]; then
            if [[ score1 -gt score3 ]]; then
                pick=1
            else
                pick=3
            fi
        elif [[ score2 -gt score3 ]]; then
            pick=2
        else
            pick=3
        fi

        if [[ pick -eq 1 ]]; then
            local lr_new_lcs
            gen_varname __LCS_COMMON lr_new_lcs

            declare -a -g "${lr_new_lcs}=()"

            local -n previous_memoized_prepared_items_ref=${pair1#*:}
            local -n c_ref=${lr_new_lcs}
            local prepared_item_to_insert

            gen_varname __LCS_PREP prepared_item_to_insert
            declare -g -a "${prepared_item_to_insert}=( ${x1@Q} ${x2@Q} ${i1@Q} ${i2@Q} )"

            c_ref=( "${previous_memoized_prepared_items_ref[@]}" "${prepared_item_to_insert}" )

            local lr_memo_key
            __lcs_make_memo_key ${i1} ${i2} lr_memo_key
            memo_map_ref["${lr_memo_key}"]="${score1}:${lr_new_lcs}"

            local -n memo_items_set=${lcs_state[__LCS_MEMO_ITEMS_SET_IDX]}
            memo_items_set["${prepared_item_to_insert}"]=x
        else
            local -n picked_pair="pair${pick}"
            local lr_memo_key=''
            __lcs_make_memo_key ${i1} ${i2} lr_memo_key
            memo_map_ref["${lr_memo_key}"]=${picked_pair}
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

function __lcs_str_score() {
    local -n score_ref=${1}; shift
    score_ref=1
    [[ ${#} -eq 0 || ${1} = "${2}" ]] || score_ref=0
}

fi
