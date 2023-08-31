#!/bin/bash

##
## Gathers information about SDK and board packages. Also collects
## info about actual build deps of board packages, which may be useful
## for verifying if SDK provides those.
##
## Reports generated:
## sdk-pkgs - contains package information for SDK
## sdk-pkgs-kv - contains package information with key values (USE, PYTHON_TARGETS, CPU_FLAGS_X86) for SDK
## board-pkgs - contains package information for board for chosen architecture
## board-bdeps - contains package information with key values (USE, PYTHON_TARGETS, CPU_FLAGS_X86) of board build dependencies
## sdk-profiles - contains a list of profiles used by the SDK, in evaluation order
## board-profiles - contains a list of profiles used by the board for the chosen architecture, in evaluation order
## sdk-package-repos - contains package information with their repos for SDK
## board-package-repos - contains package information with their repos for board
## sdk-emerge-output - contains raw emerge output for SDK being a base for other reports
## board-emerge-output - contains raw emerge output for board being a base for other reports
## *-warnings - warnings printed by emerge or other tools
##
## Parameters:
## -h: this help
##
## Positional:
## 0 - architecture (amd64 or arm64)
## 1 - reports directory
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"

if [[ ${#} -eq 1 ]] && [[ ${1} = '-h' ]]; then
    print_help
    exit 0
fi

if [[ ${#} -ne 2 ]]; then
    fail 'Expected two parameters: board architecture and reports directory'
fi

function emerge_pretend() {
    local root package
    root=${1}; shift
    package=${1}; shift

    emerge \
        --config-root="${root}" \
        --root="${root}" \
        --sysroot="${root}" \
        --pretend \
        --columns \
        --nospinner \
        --oneshot \
        --color n \
        --emptytree \
        --verbose \
        "${package}" | grep '^\['
}

function package_info_for_sdk() {
    emerge_pretend / coreos-devel/sdk-depends
}

function package_info_for_board() {
    local arch
    arch=${1}; shift

    # Replace ${arch}-usr in the output with a generic word BOARD.
    emerge_pretend "/build/${arch}-usr" coreos-devel/board-packages | \
        sed -e "s#/build/${arch}-usr/#/build/BOARD/#"
}

# eo - emerge output

function set_eo() {
    local dir=${1}; shift

    SDK_EO="${dir}/sdk-emerge-output"
    BOARD_EO="${dir}/board-emerge-output"
}

function cat_eo() {
    local kind=${1}; shift
    local suffix=${1:-}; shift

    local var_name
    var_name="${kind^^}_EO"
    local -n ref="${var_name}"

    if [[ -z "${ref+isset}" ]]; then
        fail "${var_name} unset"
    fi
    local eo_suffixed
    eo_suffixed="${ref}${suffix}"
    if [[ ! -e "${eo_suffixed}" ]]; then
        fail "${eo_suffixed} does not exist"
    fi

    cat "${eo_suffixed}"
}

#      status      package name       version slot repo                 keyvals          size
# |--------------| |----------|   |#-g1-----------#--#-g2-#|    |-g----------#-#-g-----| |---|
# [ebuild   R   ~] virtual/rust   [1.71.1:0/llvm-16::coreos]    USE="-rustfmt" FOO="bar" 0 KiB
#
# Actually, there can also be a "to /some/root/" part after "version
# slot repo" part. This usually shows up in board package reports, but
# in this case we discard everything after "version slot repo", so we
# don't need to parse it. In board bdeps reports, this part does not
# show up.
STATUS_RE='\[[^]]*]' # 0 groups
PACKAGE_NAME_RE='[^[:space:]]*' # 0 groups
VER_SLOT_REPO_RE='\[\([^]]\+\)::\([^]]\+\)]' # 2 groups
KEYVALS_RE='\([[:space:]]*[A-Za-z0-9_]*="[^"]*"\)*' # 1 group (but containing only the last pair!)
SIZE_RE='[[:digit:]]\+[[:space:]]*[[:alpha:]]*B' # 0 groups
SPACES_RE='[[:space:]]\+' # 0 groups
NONSPACES_RE='[^[:space:]]\+' # 0 groups
NONSPACES_WITH_COLON_RE='[^[:space:]]*:' # 0 groups

PKG_LINES_SED_FILTERS=(
    # drop lines not starting with [
    -e '/^\[/ ! d'
)

SLOT_INFO_SED_FILTERS=(
    # if there is not slot information in version, add :0
    #
    # assumption here is that version is a second word
    -e "/^${NONSPACES_RE}${SPACES_RE}${NONSPACES_WITH_COLON_RE}/ ! s/^\(${NONSPACES_RE}${SPACES_RE}${NONSPACES_RE}\)/\1:0/"
)

PKG_VER_SLOT_SED_FILTERS=(
    # from line like:
    #
    # [ebuild   R   ~] virtual/rust        [1.71.1:0/llvm-16::coreos]    USE="-rustfmt" 0 KiB
    #
    # extract package name, version and optionally a slot if it exists, the result would be:
    #
    # virtual/rust 1.71.1:0/llvm-16
    -e "s/^${STATUS_RE}${SPACES_RE}\(${PACKAGE_NAME_RE}\)${SPACES_RE}${VER_SLOT_REPO_RE}.*/\1 \2/"
    "${SLOT_INFO_SED_FILTERS[@]}"
)

PKG_VER_SLOT_KV_SED_FILTERS=(
    # from line like:
    #
    # [ebuild   R   ~] virtual/rust        [1.71.1:0/llvm-16::coreos]    USE="-rustfmt" 0 KiB
    #
    # extract package name, version, optionally a slot if it exists and key value pairs if any, the result would be:
    #
    # virtual/rust 1.71.1:0/llvm-16 USE="-rustfmt"
    -e "s/${STATUS_RE}${SPACES_RE}\(${PACKAGE_NAME_RE}\)${SPACES_RE}${VER_SLOT_REPO_RE}${SPACES_RE}\(${KEYVALS_RE}\)${SPACES_RE}${SIZE_RE}\$/\1 \2 \4/"
    "${SLOT_INFO_SED_FILTERS[@]}"
)

PKG_REPO_SED_FILTERS=(
    # from line like:
    #
    # [ebuild   R   ~] virtual/rust        [1.71.1:0/llvm-16::coreos]    USE="-rustfmt" 0 KiB
    #
    # extract package name and repo, the result would be:
    #
    # virtual/rust coreos
    -e "s/^${STATUS_RE}${SPACES_RE}\(${PACKAGE_NAME_RE}\)${SPACES_RE}${VER_SLOT_REPO_RE}${SPACES_RE}.*/\1 \3/"
)

function sed_eo_and_sort() {
    local kind
    kind=${1}; shift
    # rest goes to sed

    cat_eo "${kind}" | sed "${@}" | sort
}

function packages_for_sdk() {
    # args are passed to sed_eo_and_sort

    sed_eo_and_sort sdk "${@}"
}

function packages_for_board() {
    # args are passed to sed_eo_and_sort

    sed_eo_and_sort board "${@}"
}

function versions_sdk() {
    local -a sed_opts
    sed_opts=(
        "${PKG_LINES_SED_FILTERS[@]}"
        "${PKG_VER_SLOT_SED_FILTERS[@]}"
    )
    packages_for_sdk "${sed_opts[@]}"
}

function versions_sdk_with_key_values() {
    local -a sed_opts
    sed_opts=(
        "${PKG_LINES_SED_FILTERS[@]}"
        "${PKG_VER_SLOT_KV_SED_FILTERS[@]}"
    )
    packages_for_sdk "${sed_opts[@]}"
}

function versions_board() {
    local -a sed_opts
    sed_opts=(
        "${PKG_LINES_SED_FILTERS[@]}"
        -e '/to \/build\/BOARD\// ! d'
        "${PKG_VER_SLOT_SED_FILTERS[@]}"
    )
    packages_for_board "${sed_opts[@]}"
}

function board_bdeps() {
    local -a sed_opts
    sed_opts=(
        "${PKG_LINES_SED_FILTERS[@]}"
        -e '/to \/build\/BOARD\// d'
        "${PKG_VER_SLOT_KV_SED_FILTERS[@]}"
    )
    packages_for_board "${sed_opts[@]}"
}

function package_sources_sdk() {
    local -a sed_opts
    sed_opts=(
        "${PKG_REPO_SED_FILTERS[@]}"
    )
    packages_for_sdk "${sed_opts[@]}"
}

function package_sources_board() {
    local -a sed_opts
    sed_opts=(
        "${PKG_REPO_SED_FILTERS[@]}"
    )
    packages_for_board "${sed_opts[@]}"
}

function ensure_no_errors() {
    local kind

    for kind in sdk board; do
        if cat_eo "${kind}" '-warnings' | grep 'ERROR'; then
            fail "there are errors in emerge output warnings files"
        fi
    done
}

arch=${1}; shift
reports_dir=${1}; shift

mkdir -p "${reports_dir}"

set_eo "${reports_dir}"

echo 'Running pretend-emerge to get complete report for SDK'
package_info_for_sdk >"${SDK_EO}" 2>"${SDK_EO}-warnings"
echo 'Running pretend-emerge to get complete report for board'
package_info_for_board "${arch}" >"${BOARD_EO}" 2>"${BOARD_EO}-warnings"

ensure_no_errors

echo 'Generating SDK packages listing'
versions_sdk >"${reports_dir}/sdk-pkgs" 2>"${reports_dir}/sdk-pkgs-warnings"
echo 'Generating SDK packages listing with key-values (USE, PYTHON_TARGETS CPU_FLAGS_X86, etc)'
versions_sdk_with_key_values >"${reports_dir}/sdk-pkgs-kv" 2>"${reports_dir}/sdk-pkgs-kv-warnings"
echo 'Generating board packages listing'
versions_board >"${reports_dir}/board-pkgs" 2>"${reports_dir}/board-pkgs-warnings"
echo 'Generating board packages bdeps listing'
board_bdeps >"${reports_dir}/board-bdeps" 2>"${reports_dir}/board-bdeps-warnings"
echo 'Generating SDK profiles evaluation list'
ROOT=/ "${THIS_DIR}/print_profile_tree.sh" -ni -nh >"${reports_dir}/sdk-profiles" 2>"${reports_dir}/sdk-profiles-warnings"
echo 'Generating board profiles evaluation list'
ROOT="/build/${arch}-usr" "${THIS_DIR}/print_profile_tree.sh" -ni -nh >"${reports_dir}/board-profiles" 2>"${reports_dir}/board-profiles-warnings"
echo 'Generating SDK package source information'
package_sources_sdk >"${reports_dir}/sdk-package-repos" 2>"${reports_dir}/sdk-package-repos-warnings"
echo 'Generating board package source information'
package_sources_board >"${reports_dir}/board-package-repos" 2>"${reports_dir}/board-package-repos-warnings"
