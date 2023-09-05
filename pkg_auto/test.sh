#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"
source "${PKG_AUTO_DIR}/pkg_auto_lib.sh"

workdir=${1}
set_workdir_to "${workdir}"

mvm_declare g_pkg_to_tags_mvm
process_listings g_pkg_to_tags_mvm

function print_cb() {
    local k v
    k=${1}; shift
    v=${1}; shift
    # rest are tags
    printf '%s (%s):' "${k}" "${v}"
    if [[ ${#} -gt 0 ]]; then
        printf ' [%s]' "${@}"
    else
        printf ' <NO TAGS>'
    fi
    printf '\n'
}

mvm_iterate g_pkg_to_tags_mvm print_cb
mvm_unset g_pkg_to_tags_mvm
