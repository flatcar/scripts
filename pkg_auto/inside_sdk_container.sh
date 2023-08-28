#!/bin/bash

##
## Gathers information about SDK and board packages. Also collects
## info about actual build deps of board packages, which may be useful
## for verifying if SDK provides those.
##
## Reports generated:
## sdk-pkgs - contains package information for SDK
## sdk-pkgs-kv - contains package information with key values (USE, PYTHON_TARGET) for SDK
## board-pkgs - contains package information for board for chosen architecture
## board-bdeps - contains package information with key values (USE, PYTHON_TARGET) of board build dependencies
## sdk-profiles - contains a list of profiles used by the SDK, in evaluation order
## board-profiles - contains a list of profiles used by the board for the chosen architecture, in evaluation order
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
        "${package}"
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
KEYVALS_RE='\([[:space:]]*[A-Za-z_]*="[^"]*"\)*' # 1 group (but containing only the last pair!)
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

function collect_package_info_emerge() {
    local root package
    root=${1}; shift
    package=${1}; shift
    # rest goes to sed

    emerge_pretend "${root}" "${package}" | sed "${@}" | sort 2>/dev/null
}

function packages_for_board() {
    local arch
    arch=${1}; shift
    # rest is passed to collect_package_info_emerge

    collect_package_info_emerge "/build/${arch}-usr" coreos-devel/board-packages "${@}"
}

function versions_sdk() {
    local -a sed_opts
    sed_opts=(
        "${PKG_LINES_SED_FILTERS[@]}"
        "${PKG_VER_SLOT_SED_FILTERS[@]}"
    )
    collect_package_info_emerge / coreos-devel/sdk-depends "${sed_opts[@]}"
}

function versions_sdk_with_key_values() {
    local -a sed_opts
    sed_opts=(
        "${PKG_LINES_SED_FILTERS[@]}"
        "${PKG_VER_SLOT_KV_SED_FILTERS[@]}"
    )
    collect_package_info_emerge / coreos-devel/sdk-depends "${sed_opts[@]}"
}

function versions_board() {
    local arch
    arch=${1}; shift

    local -a sed_opts
    sed_opts=(
        "${PKG_LINES_SED_FILTERS[@]}" \
        -e "/to \/build\/${arch}-usr\// ! d"
        "${PKG_VER_SLOT_SED_FILTERS[@]}"
    )
    packages_for_board "${arch}" "${sed_opts[@]}"
}

function board_bdeps() {
    local arch
    arch=${1}; shift

    local -a sed_opts
    sed_opts=(
        "${PKG_LINES_SED_FILTERS[@]}" \
        -e "/to \/build\/${arch}-usr\// d"
        "${PKG_VER_SLOT_KV_SED_FILTERS[@]}"
    )
    packages_for_board "${arch}" "${sed_opts[@]}"
}

arch=${1}; shift
reports_dir=${1}; shift

mkdir -p "${reports_dir}"

echo 'Generating SDK packages listing'
versions_sdk >"${reports_dir}/sdk-pkgs" 2>"${reports_dir}/sdk-pkgs-warnings"
echo 'Generating SDK packages listing with key-values (USE, SINGLE_PYTHON, etc)'
versions_sdk_with_key_values >"${reports_dir}/sdk-pkgs-kv" 2>"${reports_dir}/sdk-pkgs-kv-warnings"
echo 'Generating board packages listing'
versions_board "${arch}" >"${reports_dir}/board-pkgs" 2>"${reports_dir}/board-pkgs-warnings"
echo 'Generating board packages bdeps listing'
board_bdeps "${arch}" >"${reports_dir}/board-bdeps" 2>"${reports_dir}/board-bdeps-warnings"
echo 'Generating SDK profiles evaluation list'
ROOT=/ "${THIS_DIR}/print_profile_tree.sh" -ni -nh >"${reports_dir}/sdk-profiles" 2>"${reports_dir}/sdk-profiles-warnings"
echo 'Generating board profiles evaluation list'
ROOT="/build/${arch}-usr" "${THIS_DIR}/print_profile_tree.sh" -ni -nh >"${reports_dir}/board-profiles" 2>"${reports_dir}/board-profiles-warnings"
