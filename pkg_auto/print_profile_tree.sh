#!/bin/bash

##
## Prints profile information in form of an inheritance tree and/or
## evaluation order.
##
## Parameters:
## -h: this help
## -ni: no inheritance tree
## -ne: no evaluation order
## -nh: no headers
##
## Environment variables:
## ROOT
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"

: "${ROOT:=/}"

print_inheritance_tree=x
print_evaluation_order=x
print_headers=x

while [[ ${#} -gt 0 ]]; do
    case ${1} in
        -h)
            print_help
            exit 0
            ;;
        -ni)
            print_inheritance_tree=
            ;;
        -ne)
            print_evaluation_order=
            ;;
        -nh)
            print_headers=
            ;;
        *)
            fail "unknown flag ${1}"
            ;;
    esac
    shift
done

all_repo_names=()
read -a all_repo_names -r < <(portageq get_repos "${ROOT}")

declare -A repo_data repo_data_r
# name to path
repo_data=()
# path to name
repo_data_r=()

for repo_name in "${all_repo_names[@]}"; do
    repo_path=$(portageq get_repo_path "${ROOT}" "${repo_name}")
    repo_path=$(realpath "${repo_path}")
    repo_data["${repo_name}"]="${repo_path}"
    repo_data_r["${repo_path}"]="${repo_name}"
done

unset all_repo_names

function get_repo_from_profile_path() {
    local path repo_dir_var_name
    path="${1}"; shift
    repo_dir_var_name="${1}"; shift
    local -n repo_dir_ref="${repo_dir_var_name}"

    # shellcheck disable=SC2034 # it's a reference to external variable
    repo_dir_ref="${path%/profiles/*}"
}

function repo_path_to_name() {
    local path name_var_name
    path="${1}"; shift
    name_var_name="${1}"; shift
    local -n name_ref="${name_var_name}"

    # shellcheck disable=SC2034 # it's a reference to external variable
    name_ref=${repo_data_r["${path}"]:-'<unknown>'}
}

function repeat_string() {
    local str ntimes out_str_var_name
    str="${1}"; shift
    ntimes="${1}"; shift
    out_str_var_name="${1}"; shift
    local -n out_str_ref="${out_str_var_name}"

    if [[ ${ntimes} -eq 0 ]]; then
        out_str_ref=""
        return 0
    elif [[ ${ntimes} -eq 1 ]]; then
        out_str_ref="${str}"
        return 0
    fi
    local add_one
    add_one=$((ntimes % 2))
    repeat_string "${str}${str}" $((ntimes / 2)) "${out_str_var_name}"
    if [[ add_one -gt 0 ]]; then
        out_str_ref+="${str}"
    fi
}

function process_profile() {
    local repo_name profile_path children_var_name
    repo_name="${1}"; shift
    profile_path="${1}"; shift
    children_var_name="${1}"; shift
    local -n children_ref="${children_var_name}"

    local parent_file line pp_new_repo_name new_profile_path pp_new_repo_path
    local -a children

    parent_file="${profile_path}/parent"
    children=()
    if [[ -e "${parent_file}" ]]; then
        while read -r line; do
            if [[ "${line}" = *:* ]]; then
                pp_new_repo_name="${line%%:*}"
                if [[ -z "${pp_new_repo_name}" ]]; then
                    pp_new_repo_name=${repo_name}
                fi
                new_profile_path="${repo_data["${pp_new_repo_name}"]}/profiles/${line#*:}"
                children+=( "${pp_new_repo_name}" "${new_profile_path}" )
            elif [[ "${line}" = /* ]]; then
                pp_new_repo_path=
                get_repo_from_profile_path "${line}" pp_new_repo_path
                pp_new_repo_name=
                repo_path_to_name "${pp_new_repo_path}" pp_new_repo_name
                children+=( "${pp_new_repo_name}" "${line}" )
            else
                children+=( "${repo_name}" "$(realpath "${profile_path}/${line}")" )
            fi
        done <"${parent_file}"
    fi

    # shellcheck disable=SC2034 # it's a reference to external variable
    children_ref=( "${children[@]}" )
}

function get_profile_name() {
    local repo_name profile_path profile_name_var_name
    repo_name="${1}"; shift
    profile_path="${1}"; shift
    profile_name_var_name="${1}"; shift
    local -n profile_name_ref="${profile_name_var_name}"

    local repo_path profile_name
    repo_path=${repo_data["${repo_name}"]}
    profile_name=${profile_path#"${repo_path}/profiles/"}

    # shellcheck disable=SC2034 # it's a reference to external variable
    profile_name_ref="${profile_name}"
}

make_profile_path="${ROOT%/}/etc/portage/make.profile"
top_profile_dir_path=$(realpath "${make_profile_path}")
top_repo_path=
get_repo_from_profile_path "${top_profile_dir_path}" top_repo_path
top_repo_name=
repo_path_to_name "${top_repo_path}" top_repo_name

if [[ -n ${print_inheritance_tree} ]]; then

set -- '0' "${top_repo_name}" "${top_profile_dir_path}"

profile_tree=()

while [[ "${#}" -gt 2 ]]; do
    indent="${1}"; shift
    repo_name="${1}"; shift
    profile_path="${1}"; shift

    lines=
    fork=
    if [[ indent -gt 0 ]]; then
        if [[ indent -gt 1 ]]; then
            repeat_string '| ' $((indent - 1)) lines
        fi
        fork='+-'
    fi
    g_profile_name=
    get_profile_name "${repo_name}" "${profile_path}" g_profile_name
    profile_tree+=( "${lines}${fork}${repo_name}:${g_profile_name}" )
    g_profile_children=()

    process_profile "${repo_name}" "${profile_path}" g_profile_children

    new_profiles=()
    new_indent=$((indent + 1))
    pc_idx=0
    while [[ $((pc_idx + 1)) -lt "${#g_profile_children[@]}" ]]; do
        new_repo_name=${g_profile_children["${pc_idx}"]}
        new_profile_path=${g_profile_children[$((pc_idx + 1))]}
        new_profiles+=( "${new_indent}" "${new_repo_name}" "${new_profile_path}" )
        pc_idx=$((pc_idx + 2))
    done

    set -- "${new_profiles[@]}" "${@}"
done

if [[ -n ${print_headers} ]]; then
    echo
    echo 'profile inheritance tree:'
    echo
fi
for line in "${profile_tree[@]}"; do
    echo "${line}"
done

fi

if [[ -n ${print_evaluation_order} ]]; then

set -- "${top_repo_name}" "${top_profile_dir_path}" '0'

profile_eval=()

while [[ "${#}" -gt 2 ]]; do
    repo_name="${1}"; shift
    profile_path="${1}"; shift
    num_parents="${1}"; shift
    # each parent is a repo name and profile path, so two items for each parent
    num_parent_items=$((num_parents * 2))
    parents=( "${@:1:${num_parent_items}}" )
    shift "${num_parent_items}"
    g_profile_children=()

    process_profile "${repo_name}" "${profile_path}" g_profile_children

    new_args=()
    if [[ "${#g_profile_children[@]}" -eq 0 ]]; then
        to_evaluate=( "${repo_name}" "${profile_path}" "${parents[@]}" )
        te_idx=0
        while [[ $((te_idx + 1)) -lt "${#to_evaluate[@]}" ]]; do
            new_repo_name=${to_evaluate["${te_idx}"]}
            new_profile_path=${to_evaluate[$((te_idx + 1))]}
            g_new_profile_name=
            get_profile_name "${new_repo_name}" "${new_profile_path}" g_new_profile_name
            profile_eval+=( "${new_repo_name}:${g_new_profile_name}" )
            te_idx=$((te_idx + 2))
        done
    else
        last_idx=$(( ${#g_profile_children[@]} - 2 ))
        pc_idx=0
        while [[ $((pc_idx + 1)) -lt "${#g_profile_children[@]}" ]]; do
            new_repo_name=${g_profile_children["${pc_idx}"]}
            new_profile_path=${g_profile_children[$((pc_idx + 1))]}
            new_args+=( "${new_repo_name}" "${new_profile_path}" )
            if [[ pc_idx -eq last_idx ]]; then
                new_args+=( $((num_parents + 1)) "${repo_name}" "${profile_path}" "${parents[@]}" )
            else
                new_args+=( 0 )
            fi
            pc_idx=$((pc_idx + 2))
        done
    fi

    set -- "${new_args[@]}" "${@}"
done

if [[ -n ${print_headers} ]]; then
    echo
    echo 'profile evaluation order:'
    echo
fi
for line in "${profile_eval[@]}"; do
    echo "${line}"
done

fi
