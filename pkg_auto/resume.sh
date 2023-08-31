#!/bin/bash

set -euo pipefail

##
## Resumes updating the packages after a report generation failure
##
## Parameters:
## -h: this help
##
## Positional:
## 0: workdir directory
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"
source "${THIS_DIR}/pkg_auto_lib.sh"

while [[ ${#} -gt 0 ]]; do
    case ${1} in
        -h)
            print_help
            exit 0
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

if [[ ${#} -ne 5 ]]; then
    fail 'expected one positional parameters: a work directory'
fi

resume_workdir_from "${1}"
generate_package_update_reports
save_new_state
