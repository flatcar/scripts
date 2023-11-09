#!/bin/bash

##
## Updates the packages
##
## Parameters:
## -w: path to use for workdir
## -h: this help
##
## Positional:
## 1: config file
## 2: new branch name with updates
## 3: gentoo repo
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/impl/stuff.sh"
source "${PKG_AUTO_IMPL_DIR}/pkg_auto_lib.sh"

up_workdir=''

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
            up_workdir=${2}
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
    fail 'expected three positional parameters: a config file, a final branch name and a path to Gentoo repo'
fi

config_file=${1}; shift
saved_branch_name=${1}; shift
gentoo=${1}; shift

create_dir_for_workdir 'up' up_workdir
setup_workdir_with_config "${up_workdir}" "${config_file}"

up_reports=''
get_workdir_config_opts 'reports' up_reports
reports_directory=$(realpath "${up_reports}")

if [[ -e "${reports_directory}" ]]; then
    info 'reports directory already exists'
else
    mkdir -p "${reports_directory}"
fi

perform_sync_with_gentoo "${gentoo}"
save_new_state "${saved_branch_name}"
generate_package_update_reports
