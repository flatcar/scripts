#!/bin/bash

##
## Enters the SDK using new state directory to debug issues.
##
## Parameters:
## -h: this help
## -w: path to use for workdir
##
## Positional:
## 1 - work directory
## 2 - arch (amd64 or arm64)
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"
source "${PKG_AUTO_DIR}/pkg_auto_lib.sh"

dns_workdir=''

while [[ ${#} -gt 0 ]]; do
    case ${1} in
        -h)
            print_help
            exit 0
            ;;
        -w)
            if [[ -z ${2:-} ]]; then
                fail 'missing value for -w'
            fi
            dns_workdir=${2}
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            fail "unknown flag '${1}'"
            ;;
        *)
            break
            ;;
    esac
done

if [[ ${#} -ne 3 ]]; then
    fail 'Expected three parameters: work directory, board architecture and a final branch name'
fi

old_workdir=${1}; shift
arch=${1}; shift
saved_branch_name=${1}; shift

dns_old_ref=''
dns_new_ref=''
get_state_refs "${old_workdir}" dns_old_ref dns_new_ref

config_file=$(mktemp)
opts=(
    -b "${old_workdir}"
    -x trap
    -n "${dns_new_ref}"
    -o "${dns_old_ref}"
)
"${PKG_AUTO_DIR}/generate_config.sh" "${opts[@]}" "${config_file}"

create_dir_for_workdir 'dns' dns_workdir
setup_workdir_with_tmp_config "${dns_workdir}" "${config_file}"
debug_new_state "${arch}"
save_new_state "${saved_branch_name}"
