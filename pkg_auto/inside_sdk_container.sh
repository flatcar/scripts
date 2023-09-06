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
## sdk-emerge-output-filtered - contains only lines with package information for SDK
## board-emerge-output-filtered - contains only lines with package information for board
## sdk-emerge-output-junk - contains only junk lines for SDK
## board-emerge-output-junk - contains only junk lines for board
## *-warnings - warnings printed by emerge or other tools
##
## Parameters:
## -h: this help
##
## Positional:
## 1 - architecture (amd64 or arm64)
## 2 - reports directory
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"

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
    fail 'Expected two parameters: board architecture and reports directory'
fi

function emerge_pretend() {
    local root package
    root=${1}; shift
    package=${1}; shift

    local -a emerge_opts=(
        --config-root="${root}"
        --root="${root}"
        --sysroot="${root}"
        --pretend
        --columns
        --nospinner
        --oneshot
        --color n
        --emptytree
        --verbose
        --verbose-conflicts
        --verbose-slot-rebuilds y
        --selective n
        --changed-deps y
        --changed-deps-report y
        --changed-slot y
        --changed-use
        --complete-graph y
        --rebuild-if-new-slot y
        --rebuild-if-new-rev y
        --with-bdeps y
    )
    local rv
    rv=0
    emerge "${emerge_opts[@]}" "${package}" || rv=${?}
    if [[ ${rv} -ne 0 ]]; then
        echo "WARNING: emerge exited with status ${rv}" >&2
    fi
}

function package_info_for_sdk() {
    emerge_pretend / coreos-devel/sdk-depends
}

function package_info_for_board() {
    local arch
    arch=${1}; shift

    emerge_pretend "/build/${arch}-usr" coreos-devel/board-packages
}

# eo - emerge output

function set_eo() {
    local dir=${1}; shift

    SDK_EO="${dir}/sdk-emerge-output"
    BOARD_EO="${dir}/board-emerge-output"
    SDK_EO_F="${SDK_EO}-filtered"
    BOARD_EO_F="${BOARD_EO}-filtered"
    SDK_EO_W="${SDK_EO}-warnings"
    BOARD_EO_W="${BOARD_EO}-warnings"
}

function cat_var() {
    local var_name
    var_name=${1}; shift
    local -n ref="${var_name}"

    if [[ -z "${ref+isset}" ]]; then
        fail "${var_name} unset"
    fi
    if [[ ! -e "${ref}" ]]; then
        fail "${ref} does not exist"
    fi

    cat "${ref}"
}

function cat_eo() {
    local kind
    kind=${1}; shift

    cat_var "${kind^^}_EO"
}

function cat_eo_f() {
    local kind
    kind=${1}; shift
    cat_var "${kind^^}_EO_F"
}

function cat_eo_w() {
    local kind
    kind=${1}; shift

    cat_var "${kind^^}_EO_W"
}

#      status      package name     version slot repo      target (opt)          keyvals          size
# |--------------| |----------| |#-g1-----------#--#-g2-#| |--|-g------| |-g----------#-#-g-----| |---|
# [ebuild   R   ~] virtual/rust [1.71.1:0/llvm-16::coreos] to /some/root USE="-rustfmt" FOO="bar" 0 KiB
#
# Actually, there can also be another "version slot repo" part between
# the first "version slot repo" and "target" part.
STATUS_RE='\[[^]]*]' # 0 groups
PACKAGE_NAME_RE='[^[:space:]]*' # 0 groups
VER_SLOT_REPO_RE='\[\([^]]\+\)::\([^]]\+\)]' # 2 groups
TARGET_RE='to[[:space:]]\+\([^[:space:]]\)\+' # 1 group
KEYVALS_RE='\([[:space:]]*[A-Za-z0-9_]*="[^"]*"\)*' # 1 group (but containing only the last pair!)
SIZE_RE='[[:digit:]]\+[[:space:]]*[[:alpha:]]*B' # 0 groups
SPACES_RE='[[:space:]]\+' # 0 groups
NONSPACES_RE='[^[:space:]]\+' # 0 groups
NONSPACES_WITH_COLON_RE='[^[:space:]]*:' # 0 groups

FULL_LINE_RE='^'"${STATUS_RE}${SPACES_RE}${PACKAGE_NAME_RE}"'\('"${SPACES_RE}${VER_SLOT_REPO_RE}"'\)\{1,2\}\('"${SPACES_RE}${TARGET_RE}"'\)\?\('"${SPACES_RE}${KEYVALS_RE}"'\)*'"${SPACES_RE}${SIZE_RE}"'$'

function filter_sdk_eo() {
    cat_eo sdk | grep -e "${FULL_LINE_RE}"
}

function filter_board_eo() {
    local arch
    arch=${1}; shift

    # Replace ${arch}-usr in the output with a generic word BOARD.
    cat_eo board | \
        grep -e "${FULL_LINE_RE}" | \
        sed -e "s#/build/${arch}-usr/#/build/BOARD/#"
}

function junk_sdk_eo() {
    cat_eo sdk | grep -v -e "${FULL_LINE_RE}"
}

function junk_board_eo() {
    cat_eo board | grep -v -e "${FULL_LINE_RE}"
}

# There may also be a line like:
#
# [blocks B      ] <dev-util/gdbus-codegen-2.76.4 ("<dev-util/gdbus-codegen-2.76.4" is soft blocking dev-libs/glib-2.76.4)
#
# But currently we don't care about those - they land in junk.

SLOT_INFO_SED_FILTERS=(
    # if there is no slot information in version, add :0
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
    -e "s/${STATUS_RE}${SPACES_RE}\(${PACKAGE_NAME_RE}\)${SPACES_RE}${VER_SLOT_REPO_RE}\(${SPACES_RE}${VER_SLOT_REPO_RE}\)\?\(${SPACES_RE}${TARGET_RE}\)\?${SPACES_RE}\(${KEYVALS_RE}\)${SPACES_RE}${SIZE_RE}\$/\1 \2 \9/"
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

    cat_eo_f "${kind}" | sed "${@}" | sort
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
        "${PKG_VER_SLOT_SED_FILTERS[@]}"
    )
    packages_for_sdk "${sed_opts[@]}"
}

function versions_sdk_with_key_values() {
    local -a sed_opts
    sed_opts=(
        "${PKG_VER_SLOT_KV_SED_FILTERS[@]}"
    )
    packages_for_sdk "${sed_opts[@]}"
}

function versions_board() {
    local -a sed_opts
    sed_opts=(
        -e '/to \/build\/BOARD\// ! d'
        "${PKG_VER_SLOT_SED_FILTERS[@]}"
    )
    packages_for_board "${sed_opts[@]}"
}

function board_bdeps() {
    local -a sed_opts
    sed_opts=(
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
        if cat_eo_w "${kind}" | grep --quiet --fixed-strings 'ERROR'; then
            fail "there are errors in emerge output warnings files"
        fi
    done
}

arch=${1}; shift
reports_dir=${1}; shift

mkdir -p "${reports_dir}"

set_eo "${reports_dir}"

echo 'Running pretend-emerge to get complete report for SDK'
package_info_for_sdk >"${SDK_EO}" 2>"${SDK_EO_W}"
echo 'Running pretend-emerge to get complete report for board'
package_info_for_board "${arch}" >"${BOARD_EO}" 2>"${BOARD_EO_W}"

ensure_no_errors

echo 'Separating emerge info from junk in SDK emerge output'
filter_sdk_eo >"${SDK_EO_F}" 2>>"${SDK_EO_W}"
junk_sdk_eo >"${SDK_EO}-junk" 2>>"${SDK_EO_W}"
echo 'Separating emerge info from junk in board emerge output'
filter_board_eo "${arch}" >"${BOARD_EO_F}" 2>>"${BOARD_EO_W}"
junk_board_eo >"${BOARD_EO}-junk" 2>>"${BOARD_EO_W}"

echo 'Generating SDK packages listing'
versions_sdk >"${reports_dir}/sdk-pkgs" 2>"${reports_dir}/sdk-pkgs-warnings"
echo 'Generating SDK packages listing with key-values (USE, PYTHON_TARGETS CPU_FLAGS_X86, etc)'
versions_sdk_with_key_values >"${reports_dir}/sdk-pkgs-kv" 2>"${reports_dir}/sdk-pkgs-kv-warnings"
echo 'Generating board packages listing'
versions_board >"${reports_dir}/board-pkgs" 2>"${reports_dir}/board-pkgs-warnings"
echo 'Generating board packages bdeps listing'
board_bdeps >"${reports_dir}/board-bdeps" 2>"${reports_dir}/board-bdeps-warnings"
echo 'Generating SDK profiles evaluation list'
ROOT=/ "${PKG_AUTO_DIR}/print_profile_tree.sh" -ni -nh >"${reports_dir}/sdk-profiles" 2>"${reports_dir}/sdk-profiles-warnings"
echo 'Generating board profiles evaluation list'
ROOT="/build/${arch}-usr" "${PKG_AUTO_DIR}/print_profile_tree.sh" -ni -nh >"${reports_dir}/board-profiles" 2>"${reports_dir}/board-profiles-warnings"
echo 'Generating SDK package source information'
package_sources_sdk >"${reports_dir}/sdk-package-repos" 2>"${reports_dir}/sdk-package-repos-warnings"
echo 'Generating board package source information'
package_sources_board >"${reports_dir}/board-package-repos" 2>"${reports_dir}/board-package-repos-warnings"
