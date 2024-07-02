#!/bin/bash

set -euo pipefail

stage1_repo=${1}

old_use_force="${stage1_repo}/profiles/coreos/targets/generic/use.force"
new_use_force="${stage1_repo}/profiles/coreos/base/use.force"

old_use_mask="${stage1_repo}/profiles/coreos/targets/generic/use.mask"
new_use_mask="${stage1_repo}/profiles/coreos/base/use.mask"

make_defaults="${stage1_repo}/profiles/coreos/targets/generic/make.defaults"

grep_cmd=(
    grep
    --fixed-strings
    --quiet
    --line-regexp
    --no-messages # swallow errors about nonexistent files
)

if ! "${grep_cmd[@]}" --regexp '-split-usr' "${old_use_force}"; then
    # No unforcing of split-usr in old use.force, not continuing
    exit 0
fi

if "${grep_cmd[@]}" --regexp '-split-usr' "${new_use_force}"; then
    # split-usr already unforced in new use.mask, not continuing
    exit 0
fi

if ! "${grep_cmd[@]}" 'split-usr' "${old_use_mask}"; then
    # No masking of split-usr in old use.mask, not continuing
    exit 0
fi

if "${grep_cmd[@]}" 'split-usr' "${new_use_mask}"; then
    # split-usr already masked in new use.mask, not continuing
    exit 0
fi

if ! grep --quiet --no-messages '^USE="[^"]*\bsymlink-usr\b' "${make_defaults}"; then
    # symlink-usr dropped from make.defaults, not continuing
    exit 0
fi

sed -i -e '/^-split-usr$/d' "${old_use_force}"
printf '%s\n' '-split-usr' >>"${new_use_force}"
sed -i -e '/^split-usr$/d' "${old_use_mask}"
printf '%s\n' 'split-usr' >>"${new_use_mask}"
sed -i -e 's/\(^USE="[^"]*\)\bsymlink-usr\b\(.*\)/\1\2/' "${make_defaults}"
sed -i -e 's/\(^USE="[^"]*\)\bsymlink-usr\b\(.*\)/\1\2/' "${make_defaults}"
