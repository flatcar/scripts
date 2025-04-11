#!/bin/bash

set -euo pipefail

##
## Generate a config.
##
## Parameters:
## -a: aux directory
## -d: debug package - list many times
## -h: this help
## -i: override SDK image, it should be a valid docker image with an
##     optional tag
## -n: new base
## -o: old base
## -r: reports directory
## -s: scripts directory
## -x: cleanup opts
##
## Positional:
## 1: path for config file
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/impl/util.sh"
source "${PKG_AUTO_IMPL_DIR}/cleanups.sh"

gc_aux_directory=''
gc_new_base=''
gc_old_base=''
gc_reports_directory=''
gc_scripts_directory=''
gc_cleanup_opts=''
gc_image_override=''
gc_debug_packages=()

declare -A opt_map
opt_map=(
    ['-a']=gc_aux_directory
    ['-i']=gc_image_override
    ['-n']=gc_new_base
    ['-o']=gc_old_base
    ['-r']=gc_reports_directory
    ['-s']=gc_scripts_directory
    ['-x']=gc_cleanup_opts
)

declare -a gc_arches
get_valid_arches gc_arches

while [[ ${#} -gt 0 ]]; do
    case ${1} in
        -d)
            if [[ -z ${2:-} ]]; then
                fail 'missing value for -d'
            fi
            gc_debug_packages+=( "${2}" )
            shift 2
            ;;
        -h)
            print_help
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            var_name=${opt_map["${1}"]:-}
            if [[ -z ${var_name} ]]; then
                fail "unknown flag '${1}'"
            fi
            if [[ -z ${2:-} ]]; then
                fail 'missing value for -w'
            fi
            declare -n ref="${var_name}"
            ref=${2}
            unset -n ref
            unset var_name
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

join_by gc_debug_packages_csv ',' "${gc_debug_packages[@]}"

declare -a pairs
pairs=(
    'scripts' gc_scripts_directory
    'aux' gc_aux_directory
    'reports' gc_reports_directory
    'old-base' gc_old_base
    'new-base' gc_new_base
    'cleanups' gc_cleanup_opts
    'sdk-image-override' gc_image_override
    'debug-packages' gc_debug_packages_csv
)

if [[ ${#} -ne 1 ]]; then
    fail 'expected one positional parameters: a path for the config'
fi

config=${1}; shift

{
    opt_idx=0
    name_idx=1
    while [[ ${name_idx} -lt "${#pairs[@]}" ]]; do
        opt=${pairs["${opt_idx}"]}
        name=${pairs["${name_idx}"]}
        opt_idx=$((opt_idx + 2))
        name_idx=$((name_idx + 2))
        declare -n ref="${name}"
        if [[ -n ${ref:-} ]]; then
            printf '%s: %s\n' "${opt}" "${ref}"
        fi
        unset -n ref
    done
    unset opt_idx name_idx
} >"${config}"

info 'Done, but note that the config is not guaranteed to be valid!'
