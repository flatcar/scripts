#!/bin/bash

# This script sorts the config files. It can be called with several
# config files too, so it will sort each file separately.

set -euo pipefail

c_locale_sort()
{
    LC_ALL=C sort "${@}"
}

for cfgfile in "${@}"
do
    mapfile -t lines <"${cfgfile}"
    declare -A variables # a hash map
    for line in "${lines[@]}"
    do
        var="${line%%=*}"
        var="${var#\# }"
        var="${var%% *}"
        if [[ ${variables[${var}]+isset} ]]
        then
            echo "${cfgfile}: overriding ${var}"
        else
            variables[${var}]=1
            declare -a "LINES_FOR_${var}"
        fi
        declare -n var_lines="LINES_FOR_${var}"
        var_lines+=("${line}")
        unset -n var_lines
    done
    mapfile -t sorted_variables < <(printf '%s\n' "${!variables[@]}" | c_locale_sort)
    truncate --size=0 "${cfgfile}"
    for var in "${sorted_variables[@]}"
    do
        declare -n var_lines="LINES_FOR_${var}"
        printf '%s\n' "${var_lines[@]}" >>"${cfgfile}"
        unset var_lines
        unset -n var_lines
    done
    unset sorted_variables
    unset lines
    unset variables
done
