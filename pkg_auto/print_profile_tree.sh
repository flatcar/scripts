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

: ${ROOT:=/}

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

function split_repo_and_profile {
    local path srap_repo_dir_var_name srap_profile_name_var_name
    path="${1}"; shift
    srap_repo_dir_var_name="${1}"; shift
    local -n srap_repo_dir_var="${srap_repo_dir_var_name}"
    srap_profile_name_var_name="${1}"; shift
    local -n srap_profile_name_var="${srap_profile_name_var_name}"

    srap_repo_dir_var="${path%/profiles/*}"
    srap_profile_name_var="${path#*/profiles/}"
}

function repo_path_to_name {
    local path rptn_name_var_name
    path="${1}"; shift
    rptn_name_var_name="${1}"; shift
    local -n rptn_name_var="${rptn_name_var_name}"

    rptn_name_var="${repo_data_r["${path}"]:-'<unknown>'}"
}

function repeat_string {
    local str ntimes rs_out_str_var_name
    str="${1}"; shift
    ntimes="${1}"; shift
    rs_out_str_var_name="${1}"; shift
    local -n rs_out_str_var="${rs_out_str_var_name}"

    if [[ ${ntimes} -eq 0 ]]; then
        rs_out_str_var=""
        return 0
    elif [[ ${ntimes} -eq 1 ]]; then
        rs_out_str_var="${str}"
        return 0
    fi
    local add_one
    add_one=$((ntimes % 2))
    repeat_string "${str}${str}" $((ntimes / 2)) "${rs_out_str_var_name}"
    if [[ add_one -gt 0 ]]; then
        rs_out_str_var+="${str}"
    fi
}

function process_profile {
    local repo_name profile_path pp_children_var_name
    repo_name="${1}"; shift
    profile_path="${1}"; shift
    pp_children_var_name="${1}"; shift

    local parent_file line new_repo_name new_profile_path new_repo_path new_profile_name
    local -a children
    local -n pp_children_var="${pp_children_var_name}"

    parent_file="${profile_path}/parent"
    pp_children=()
    if [[ -e "${parent_file}" ]]; then
        while read -r line; do
            if [[ "${line}" = *:* ]]; then
                new_repo_name="${line%%:*}"
                if [[ -z "${new_repo_name}" ]]; then
                    new_repo_name=${repo_name}
                fi
                new_profile_path="${repo_data["${new_repo_name}"]}/profiles/${line#*:}"
                pp_children+=( "${new_repo_name}" "${new_profile_path}" )
            elif [[ "${line}" = /* ]]; then
                new_repo_path=
                new_profile_name=
                split_repo_and_profile "${line}" new_repo_path new_profile_name
                new_repo_name=
                repo_path_to_name "${new_repo_path}" new_repo_name
                pp_children+=( "${new_repo_name}" "${line}" )
            else
                pp_children+=( "${repo_name}" "$(realpath "${profile_path}/${line}")" )
            fi
        done <"${parent_file}"
    fi

    pp_children_var=( "${pp_children[@]}" )
}

function get_profile_name {
    local repo_name profile_path gpn_profile_name_var_name
    repo_name="${1}"; shift
    profile_path="${1}"; shift
    gpn_profile_name_var_name="${1}"; shift
    local -n gpn_profile_name_var="${gpn_profile_name_var_name}"

    local repo_path gpn_profile_name
    repo_path=${repo_data["${repo_name}"]}
    gpn_profile_name=${profile_path#"${repo_path}/profiles/"}

    gpn_profile_name_var="${gpn_profile_name}"
}

make_profile_path="${ROOT%/}/etc/portage/make.profile"
top_profile_dir_path=$(realpath "${make_profile_path}")
top_profile_name=
top_repo_path=
split_repo_and_profile "${top_profile_dir_path}" top_repo_path top_profile_name
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
    profile_name=
    get_profile_name "${repo_name}" "${profile_path}" profile_name
    profile_tree+=( "${lines}${fork}${repo_name}:${profile_name}" )
    profile_children=()

    process_profile "${repo_name}" "${profile_path}" profile_children

    new_profiles=()
    new_indent=$((indent + 1))
    pc_idx=0
    while [[ $((pc_idx + 1)) -lt "${#profile_children[@]}" ]]; do
        new_repo_name=${profile_children["${pc_idx}"]}
        new_profile_path=${profile_children[$((pc_idx + 1))]}
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
    profile_children=()

    process_profile "${repo_name}" "${profile_path}" profile_children

    new_args=()
    if [[ "${#profile_children[@]}" -eq 0 ]]; then
        to_evaluate=( "${repo_name}" "${profile_path}" "${parents[@]}" )
        te_idx=0
        while [[ $((te_idx + 1)) -lt "${#to_evaluate[@]}" ]]; do
            new_repo_name=${to_evaluate["${te_idx}"]}
            new_profile_path=${to_evaluate[$((te_idx + 1))]}
            new_profile_name=
            get_profile_name "${new_repo_name}" "${new_profile_path}" new_profile_name
            profile_eval+=( "${new_repo_name}:${new_profile_name}" )
            te_idx=$((te_idx + 2))
        done
    else
        last_idx=$(( ${#profile_children[@]} - 2 ))
        pc_idx=0
        while [[ $((pc_idx + 1)) -lt "${#profile_children[@]}" ]]; do
            new_repo_name=${profile_children["${pc_idx}"]}
            new_profile_path=${profile_children[$((pc_idx + 1))]}
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
