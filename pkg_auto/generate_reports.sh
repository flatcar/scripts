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

source "$(dirname "${BASH_SOURCE[0]}")/impl/util.sh"
source "${PKG_AUTO_IMPL_DIR}/pkg_auto_lib.sh"

workdir=''

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
            workdir=${2}
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

setup_workdir_with_config "${workdir}" "${config_file}"
generate_package_update_reports
