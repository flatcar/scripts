#!/bin/bash
set -x
set -euo pipefail

stage1_repo=${1}
new_repo=${2}
update_seed_file=${3}

cat=sys-libs
pkg=libxcrypt

if [[ -d "${stage1_repo}/${cat}/${pkg}" ]]; then
    # libxcrypt is already a part of portage-stable, nothing to do
    exit 0
fi

mkdir -p "${stage1_repo}/${cat}"
cp -a "${new_repo}/${cat}/${pkg}" "${stage1_repo}/${cat}/${pkg}"
echo x >"${update_seed_file}"
