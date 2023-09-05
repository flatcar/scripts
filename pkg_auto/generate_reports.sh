#!/bin/bash

set -euo pipefail

##
## Generates reports.
##
## Parameters:
## -w: path to use for workdir
## -h: this help
##
## Positional:
## 1: config file
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"
source "${PKG_AUTO_DIR}/pkg_auto_lib.sh"

gr_workdir=''

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
            gr_workdir=${2}
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

if [[ ${#} -ne 1 ]]; then
    fail 'expected one positional parameter: a config file'
fi

config_file=${1}; shift

create_dir_for_workdir 'gr' gr_workdir
setup_workdir_with_config "${gr_workdir}" "${config_file}"

gr_reports=''
get_workdir_config_opts 'reports' gr_reports
reports_directory=$(realpath "${gr_reports}")

if [[ -e "${reports_directory}" ]]; then
    info 'reports directory already exists'
else
    mkdir -p "${reports_directory}"
fi

generate_package_update_reports
