#!/bin/bash
set -x
set -euo pipefail

stage1_repo=${1}
new_repo=${2}
update_seed_file=${3}

base_profile_dir='profiles/coreos/base'

declare -A fixups_old=(
    ['package.mask']='>=virtual/libcrypt-2'
    ['package.unmask']='=virtual/libcrypt-1-r1'
    ['package.use.force']='sys-libs/glibc crypt'
    ['package.use.mask']='sys-libs/glibc -crypt'
)

declare -A fixups_new=(
    ['package.mask']='>=virtual/libcrypt-2'
    ['package.unmask']='<virtual/libcrypt-2'
    ['package.use.force']='sys-libs/glibc crypt'
    ['package.use.mask']='sys-libs/glibc -crypt'
)

for var_name in fixups_old fixups_new; do
    declare -n fixups="${var_name}"

    skip=''
    for f in "${!fixups[@]}"; do
        l=${fixups["${f}"]}
        ff="${stage1_repo}/${base_profile_dir}/${f}"
        if ! grep --quiet --fixed-strings --line-regexp --regexp="${l}" -- "${ff}"; then
            # fixup not applicable, try next one
            skip=x
            break
        fi
    done

    if [[ -n ${skip} ]]; then
        unset -n fixups
        continue
    fi

    for f in "${!fixups[@]}"; do
        l=${fixups["${f}"]}
        ff="${stage1_repo}/${base_profile_dir}/${f}"
        ffb="${ff}.bak"
        mv "${ff}" "${ffb}"
        grep --invert-match --fixed-strings --line-regexp --regexp="${l}" -- "${ffb}" >"${ff}"
    done
    echo x >"${update_seed_file}"
    exit 0
done
