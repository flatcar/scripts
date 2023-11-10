#!/bin/bash

if [[ -z ${__INSIDE_SDK_CONTAINER_LIB_SH_INCLUDED__:-} ]]; then
__INSIDE_SDK_CONTAINER_LIB_SH_INCLUDED__=x

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"

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
        --changed-deps y
        --changed-deps-report y
        --changed-slot y
        --changed-use
        --newuse
        --complete-graph y
        --deep
        --rebuild-if-new-slot y
        --rebuild-if-unbuilt y
        --with-bdeps y
        --dynamic-deps y
        --update
        --ignore-built-slot-operator-deps y
        --selective n
    )
    local rv
    rv=0
    emerge "${emerge_opts[@]}" "${package}" || rv=${?}
    if [[ ${rv} -ne 0 ]]; then
        echo "WARNING: emerge exited with status ${rv}" >&2
    fi
}

function package_info_for_sdk() {
    local root
    root='/'

    ignore_crossdev_stuff "${root}"
    emerge_pretend "${root}" coreos-devel/sdk-depends
    revert_crossdev_stuff "${root}"
}

function package_info_for_board() {
    local arch
    arch=${1}; shift

    local root
    root="/build/${arch}-usr"

    # Ignore crossdev stuff in both SDK root and board root - emerge
    # may query SDK stuff for the board packages.
    ignore_crossdev_stuff /
    ignore_crossdev_stuff "${root}"
    emerge_pretend "${root}" coreos-devel/board-packages
    revert_crossdev_stuff "${root}"
    revert_crossdev_stuff /
}

# eo - emerge output

function set_eo() {
    local dir=${1}; shift

    SDK_EO="${dir}/sdk-emerge-output"
    BOARD_EO="${dir}/board-emerge-output"
    # shellcheck disable=SC2034 # used indirectly in cat_eo_f
    SDK_EO_F="${SDK_EO}-filtered"
    # shellcheck disable=SC2034 # used indirectly in cat_eo_f
    BOARD_EO_F="${BOARD_EO}-filtered"
    # shellcheck disable=SC2034 # used indirectly in cat_eo_w
    SDK_EO_W="${SDK_EO}-warnings"
    # shellcheck disable=SC2034 # used indirectly in cat_eo_w
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
    cat_eo sdk | xgrep -e "${FULL_LINE_RE}"
}

function filter_board_eo() {
    local arch
    arch=${1}; shift

    # Replace ${arch}-usr in the output with a generic word BOARD.
    cat_eo board | \
        xgrep -e "${FULL_LINE_RE}" | \
        sed -e "s#/build/${arch}-usr/#/build/BOARD/#"
}

function junk_sdk_eo() {
    cat_eo sdk | xgrep -v -e "${FULL_LINE_RE}"
}

function junk_board_eo() {
    cat_eo board | xgrep -v -e "${FULL_LINE_RE}"
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

function get_provided_file() {
    local root path_var_name
    root=${1}; shift
    path_var_name=${1}; shift
    local -n path_ref="${path_var_name}"

    # shellcheck disable=SC2034 # reference to external variable
    path_ref="${root}/etc/portage/profile/package.provided/ignore_cross_packages"
}

# Marks packages coming from crossdev repo as provided at a very high
# version. We do this, because updating their native counterparts will
# cause emerge to complain that cross-<triplet>/<package> is masked
# (like for sys-libs/glibc and cross-x86_64-cros-linux-gnu/glibc),
# because it has no keywords. In theory, we could try updating
# <ROOT>/etc/portage/package.mask/cross-<triplet> file created by the
# crossdev tool to unmask the new version, but it's an unnecessary
# hassle - native and cross package are supposed to be the same ebuild
# anyway, so update information about cross package is redundant.
#
# Parameters:
# 1 - root directory
# 2 - ID of the crossdev repository (optional, defaults to x-crossdev)
function ignore_crossdev_stuff() {
    local root crossdev_repo_id
    root=${1}; shift
    crossdev_repo_id=${1:-x-crossdev}; shift || :

    local crossdev_repo_path
    crossdev_repo_path=$(portageq get_repo_path "${root}" "${crossdev_repo_id}")

    local ics_path ics_dir
    get_provided_file "${root}" ics_path
    dirname_out "${ics_path}" ics_dir

    sudo mkdir -p "${ics_dir}"
    env --chdir="${crossdev_repo_path}" find -L . -name '*.ebuild' | sed 's#^./\([^/]*/[^/]*\).*#\1-9999#' | sort -u | sudo tee "${ics_path}" >/dev/null
}

# Reverts effects of the ignore_crossdev_stuff function.
#
# Parameters:
# 1 - root directory
function revert_crossdev_stuff() {
    local root
    root=${1}; shift

    local ics_path ics_dir
    get_provided_file "${root}" ics_path
    dirname_out "${ics_path}" ics_dir

    sudo rm -f "${ics_path}"
    if dir_is_empty "${ics_dir}"; then
        sudo rmdir "${ics_dir}"
    fi
}

function ensure_valid_reports() {
    local kind var_name
    for kind in sdk board; do
        var_name="${kind^^}_EO_F"
        if [[ ! -s ${!var_name} ]]; then
            fail "report files are missing or are empty"
        fi
    done
}

function clean_empty_warning_files() {
    local dir
    dir=${1}; shift

    local file
    for file in "${dir}/"*'-warnings'; do
        if [[ ! -s ${file} ]]; then
            rm -f "${file}"
        fi
    done
}

fi
