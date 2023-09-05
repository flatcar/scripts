#!/bin/bash

set -euo pipefail

##
## Generate a config.
##
## Parameters:
## -a: aux directory
## -b: base workdir - use config from passed workdir to fill unspecified options
## -h: this help
## -i: SDK image override in form of ${arch}:${name},
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

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"
source "${PKG_AUTO_DIR}/pkg_auto_lib.sh"

base_workdir=''

gc_aux_directory=''
gc_new_base=''
gc_old_base=''
gc_reports_directory=''
gc_scripts_directory=''
gc_cleanup_opts=''
# ${arch}_sdk_img are declared on demand

declare -A opt_map
opt_map=(
    ['-a']=gc_aux_directory
    ['-b']=gc_base_workdir
    ['-n']=gc_new_base
    ['-o']=gc_old_base
    ['-r']=gc_reports_directory
    ['-s']=gc_scripts_directory
    ['-x']=gc_cleanup_opts
)

while [[ ${#} -gt 0 ]]; do
    case ${1} in
        -h)
            print_help
            exit 0
            ;;
        -i)
            if [[ -z ${2:-} ]]; then
                fail 'missing value for -i'
            fi
            arch=${2%%:*}
            image_name=${2#*:}
            var_name="gc_${arch}_sdk_img"
            unset arch
            declare -n ref="${var_name}"
            unset var_name
            ref=${image_name}
            unset image_name
            unset -n ref
            shift 2
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

declare -a pairs
pairs=(
    'scripts' gc_scripts_directory
    'aux' gc_aux_directory
    'reports' gc_reports_directory
    'old-base' gc_old_base
    'new-base' gc_new_base
    'cleanups' gc_cleanup_opts
    'amd64-sdk-img' gc_arm64_sdk_img
    'arm64-sdk-img' gc_amd64_sdk_img
)

if [[ -z ${base_workdir} ]]; then
    unset_values=()
    opt_idx=0
    name_idx=1
    while [[ ${name_idx} -lt "${#pairs[@]}" ]]; do
        opt=${pairs["${opt_idx}"]}
        name=${pairs["${name_idx}"]}
        opt_idx=$((opt_idx + 2))
        name_idx=$((name_idx + 2))
        declare -n ref="${name}"
        if [[ -z ${ref:-} ]]; then
            unset_values+=( "${opt}" "${name}" )
        fi
        unset -n ref
    done
    get_config_opts "${base_workdir}/config" "${pairs[@]}"
    unset opt_idx name_idx unset_values
fi

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

info 'The config is not guaranteed to be valid!
