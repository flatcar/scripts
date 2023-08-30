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
## 0: scripts directory
## 1: Gentoo directory
## 2: listings directory
## 3: new branch name with updates
## 4: reports directory
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"
source "${THIS_DIR}/pkg_auto_lib.sh"

cleanup_setup_args=( 'ignore' )
force_reports_dir_remove=''
scripts_base='origin/main'
work_directory=''
declare -A up_sdk_image_overrides
up_sdk_image_overrides=()

while [[ ${#} -gt 0 ]]; do
    case ${1} in
        --rm)
            cleanup_setup_args=( 'trap' )
            shift
            ;;
        -b)
            if [[ -z ${2:-} ]]; then
                fail 'missing value for -b'
            fi
            scripts_base=${2}
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
        -o)
            if [[ -z ${2:-} ]]; then
                fail 'missing value for -w'
            fi
            arch=${2%%:*}
            image_name=${2#*:}
            # shellcheck disable=SC2034 # used indirectly below
            up_sdk_image_overrides["${arch}"]=${image_name}
            shift 2
            unset arch image_name
            ;;
        -w)
            if [[ -z ${2:-} ]]; then
                fail 'missing value for -w'
            fi
            work_directory=$(realpath "${2}")
            shift 2
            ;;
        -x)
            if [[ -z ${2:-} ]]; then
                fail 'missing value for -x'
            fi
            cleanup_setup_args=( 'file' "$(realpath "${2}")" )
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

if [[ ${#} -ne 5 ]]; then
    fail 'expected five positional parameters: a scripts directory, a Gentoo directory, a listings directory, a result branch name and reports directory'
fi

scripts=$(realpath "${1}"); shift
gentoo=$(realpath "${1}"); shift
listings_directory=$(realpath "${1}"); shift
branch_name=${1}; shift
reports_directory=$(realpath "${1}"); shift

if [[ -e "${reports_directory}" ]]; then
    if [[ -n "${force_reports_dir_remove}" ]]; then
        rm -rf "${reports_directory}"
    else
        fail "reports directory at '${reports_directory}' already exists"
    fi
fi
mkdir -p "${reports_directory}"

setup_cleanups "${cleanup_setup_args[@]}"
setup_workdir "${listings_directory}" "${work_directory}"

if [[ ${cleanup_setup_args[0]} = 'ignore' ]]; then
    echo "Workdir: ${WORKDIR}"
fi

setup_worktrees_in_workdir "${scripts}" "${scripts_base}" "${gentoo}" "${reports_directory}"
override_sdk_image_names up_sdk_image_overrides
unset up_sdk_image_overrides
perform_sync_with_gentoo
generate_package_update_reports
save_new_state "${branch_name}"
