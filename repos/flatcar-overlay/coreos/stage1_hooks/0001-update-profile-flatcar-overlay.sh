#!/bin/bash
set -x
set -euo pipefail

stage1_repo="${1}"
new_repo="${2}"
parent_file='profiles/coreos/amd64/parent'
old_parent_line='portage-stable:default/linux/amd64/17.0/no-multilib/hardened'
stage1_parent="${stage1_repo}/${parent_file}"
new_parent="${new_repo}/${parent_file}"

if [[ ! -e "${new_parent}" ]]; then
    echo "no file '${parent_file}' in new repo, nothing to do"
    exit 0
fi

if [[ ! -e "${stage1_parent}" ]]; then
    echo "no file '${parent_file}' in stage1 repo, nothing to do"
    exit 0
fi

if grep --quiet --fixed-strings --line-regexp --regexp="${old_parent_line}" -- "${stage1_parent}"; then
    rm -f "${stage1_parent}"
    cp -a "${new_parent}" "${stage1_parent}"
fi
