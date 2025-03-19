#!/bin/bash

if [[ -z ${__DEBUG_SH_INCLUDED__:-} ]]; then
__DEBUG_SH_INCLUDED__=x

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

declare -gA __D_DEBUG_PACKAGES=()

function pkg_debug_add() {
    if [[ ${#} -eq 0 ]]; then
        return
    fi
    if ! declare -p __D_DEBUG_PACKAGES >/dev/null 2>&1; then
        declare -gA __D_DEBUG_PACKAGES=()
    fi
    local pkg
    for pkg; do
        __D_DEBUG_PACKAGES["${pkg}"]=x
    done
}

function pkg_debug_reset() {
    unset __D_DEBUG_PACKAGES __D_DEBUG
}

# Enables debug logs when specific packages are processed.
#
# Params:
#
# @ - package names to enable debugging for
function pkg_debug_enable() {
    local -A pkg_set=()
    local -a vals=()
    local pkg
    for pkg; do
        if [[ -n ${pkg_set["${pkg}"]:-} ]]; then
            continue
        fi
        pkg_set["${pkg}"]=x
        if [[ -n ${__D_DEBUG_PACKAGES["${pkg}"]:-} ]]; then
            vals+=( "${pkg}" )
        fi
    done
    if [[ ${#vals[@]} -gt 0 ]]; then
        declare -g __D_DEBUG
        join_by __D_DEBUG ',' "${vals[@]}"
    fi
}

function pkg_debug_packages() {
    local -n pkg_names_ref=${1}; shift

    pkg_names_ref=( "${!__D_DEBUG_PACKAGES[@]}" )
}

function pkg_debug_enabled() {
    local -i ret=0
    [[ -n ${__D_DEBUG:-} ]] || ret=1
    return ${ret}
}

# Disables debug logs to be printed.
function pkg_debug_disable() {
    unset __D_DEBUG
}

# Prints passed parameters if debugging is enabled.
#
# Params:
#
# @ - parameters to print
function pkg_debug() {
    if [[ -n ${__D_DEBUG:-} ]]; then
        pkg_debug_print_c "${__D_DEBUG}" "${@}"
    fi
}

# Prints passed lines if debugging is enabled.
#
# Params:
#
# @ - lines to print
function pkg_debug_lines() {
    if [[ -n ${__D_DEBUG:-} ]]; then
        pkg_debug_print_lines_c "${__D_DEBUG}" "${@}"
    fi
}

# Prints passed parameters unconditionally with debug
# formatting. Useful for more complicated debugging logic using
# pkg_debug_enabled.
#
# Params:
#
# @ - parameters to print
function pkg_debug_print() {
    if [[ -z ${__D_DEBUG:+notempty} ]]; then
        info "bad use of pkg_debug_print, __D_DEBUG is unset"
        debug_stacktrace
        fail '<print failwhale here>'
    fi
    pkg_debug_print_c "${__D_DEBUG}" "${@}"
}

# Prints passed lines unconditionally with debug formatting. Useful
# for more complicated debugging logic using pkg_debug_enabled.
#
# Params:
#
# @ - lines to print
function pkg_debug_print_lines() {
    if [[ -z ${__D_DEBUG:+notempty} ]]; then
        info "bad use of pkg_debug_print_lines, __D_DEBUG is unset"
        debug_stacktrace
        fail '<print failwhale here>'
    fi
    pkg_debug_print_lines_c "${__D_DEBUG}" "${@}"
}

# Prints passed parameters unconditionally with custom debug
# formatting. Useful for more complicated debugging logic using
# pkg_debug_packages.
#
# Params:
#
# 1 - comma-separated package names
# @ - parameters to print
function pkg_debug_print_c() {
    local d_debug=${1}
    info "DEBUG(${d_debug}): ${*}"
}

# Prints passed lines unconditionally with debug formatting. Useful
# for more complicated debugging logic using pkg_debug_packages.
#
# Params:
#
# 1 - comma-separated package names
# @ - lines to print
function pkg_debug_print_lines_c() {
    local d_debug=${1}
    info_lines "${@/#/"DEBUG(${d_debug}): "}"
}

fi
