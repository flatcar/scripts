#!/bin/bash

##
## Print all the places in the scripts repository where the given
## package is mentioned. It's sort of like grep, but a bit smarter and
## with a slightly better output.
##
## Parameters:
## -h: this help
##
## Positional:
## 1: scripts repo
## 2: package name
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/impl/pkg_auto_lib.sh"

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

if [[ ${#} -ne 2 ]]; then
    fail 'Expected two positional parameters: a path to scripts repository and a package name'
fi

generate_mention_report_for_package "${1}" "${2}"
