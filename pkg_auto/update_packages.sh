#!/bin/bash

##
## Updates the packages
##
## Parameters:
## --rm: cleanup on exit
## -b: scripts base, defaults to origin/main
## -f: remove reports directory if it exists at startup
## -h: this help
## -o: override SDK image name, value should be <arch>:<image_name>
## -w: path to use for work directory
## -x: cleanup file
##
## Positional:
## 1: scripts directory
## 2: Gentoo directory
## 3: listings directory
## 4: new branch name with updates
## 5: reports directory
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"
source "${THIS_DIR}/pkg_auto_lib.sh"

declare -a setup_workdir_args
setup_workdir_args=()
force_reports_dir_remove=''

while [[ ${#} -gt 0 ]]; do
    case ${1} in
        --rm|)
            setup_workdir_args+=( "${1}" )
            shift
            ;;
        -b|-o|-w|-x)
            if [[ -z ${2:-} ]]; then
                fail "missing value for ${1}"
            fi
            setup_workdir_args+=( "${1}" "${2}" )
            shift 2
            ;;
        -f)
            force_reports_dir_remove=x
            shift
            ;;
        -h)
            print_help
            exit 0
            ;;
        --)
            setup_workdir_args+=( "${1}" )
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

setup_workdir_args+=( "${@}" )

setup_workdir_full "${setup_workdir_args[@]}"

reports_directory=$(realpath "${5}")

if [[ -e "${reports_directory}" ]]; then
    if [[ -n "${force_reports_dir_remove}" ]]; then
        rm -rf "${reports_directory}"
    else
        fail "reports directory at '${reports_directory}' already exists"
    fi
fi
mkdir -p "${reports_directory}"

perform_sync_with_gentoo
generate_package_update_reports
save_new_state
