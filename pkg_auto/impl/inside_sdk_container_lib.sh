#!/bin/bash

if [[ -z ${__INSIDE_SDK_CONTAINER_LIB_SH_INCLUDED__:-} ]]; then
__INSIDE_SDK_CONTAINER_LIB_SH_INCLUDED__=x

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

# Invokes emerge to get a report about built packages for a given
# metapackage in the given root that has a portage configuration.
#
# Params:
#
# 1 - root filesystem with the portage config
# @ - packages and metapackages to get the deps from
function emerge_pretend() {
    local root
    root=${1}; shift

    # Probably a bunch of those flags are not necessary, but I'm not
    # touching it - they seem to be working. :)
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
        --keep-going y
    )
    local rv
    rv=0
    emerge "${emerge_opts[@]}" "${@}" || rv=${?}
    if [[ ${rv} -ne 0 ]]; then
        echo "WARNING: emerge exited with status ${rv}" >&2
    fi
}

# Gets package list for SDK.
function package_info_for_sdk() {
    local root='/' rust_slot d arches='' match='|' awk_code='{ print $'
    local -i awk_idx=6

    for d in /build/*-usr; do
        d=${d#/build/}
        d=${d%-usr}
        if [[ -z ${arches} ]]; then
            arches=${d}
        else
            arches+=",${d}"
        fi
        match+=' +'
        : $((++awk_idx))
    done
    match+=' |'
    awk_code+=${awk_idx}
    awk_code+=' }'

    # rust is annoying - it is slotted, thus parallel-installable and
    # also bdepends on some older version of rust and all of it causes
    # emerge to just pick up the rust slot that already exists in the
    # SDK instead of the latest stable one
    #
    # let's try to figure out the latest stable rust slot then and
    # tell emerge to pick that one
    #
    # the output of equery is something like this (assuming
    # architectures are amd64 and arm64):
    #
    # '             1.87.0-r1   | + + | 8 o 1.87.0 | portage-stable'
    #
    # (so version, followed by stability markers, followed by eapi,
    # some "unused" thing, then slot, the repo name, the "|" are table
    # lines)
    #
    # the `| + + |` part means that the package is stable for both
    # architectures, so we want to get the last line that matches this
    # part
    #
    # from that line we want to print the slot which is at index 6 +
    # number of architectures (in the example output, the index is 8)
    rust_slot=$(equery --no-color keywords --arch "${arches}" dev-lang/rust | \
        grep --fixed-strings "${match}" | \
        tail -n1 | \
        awk "${awk_code}")

    ignore_crossdev_stuff "${root}"
    # stage4 build of SDK builds coreos-devel/sdk-depends, fsscript
    # pulls in cross toolchains with crossdev (which we have just
    # ignored) and dev-lang/rust
    emerge_pretend "${root}" coreos-devel/sdk-depends dev-lang/rust:"${rust_slot}"
    revert_crossdev_stuff "${root}"
}

# Gets package list for board of a given architecture.
#
# Params:
#
# 1 - architecture
function package_info_for_board() {
    local arch
    arch=${1}; shift

    local root
    root="/build/${arch}-usr"

    local output_file
    output_file=$(mktemp --tmpdir 'emerge-output.XXXXXXXX')

    # Ignore crossdev stuff in both SDK root and board root - emerge
    # may query SDK stuff for the board packages.
    ignore_crossdev_stuff /
    ignore_crossdev_stuff "${root}"
    emerge_pretend "${root}" coreos-devel/board-packages | tee "${output_file}"

    # There are packages that are installed only in sysexts and are
    # not pulled in by the coreos-devel/board-packages
    # metapackage. The reason could be that we pull several
    # non-parallel-installable subslots of the same package for
    # different sysexts (x11-drivers/nvidia-drivers for
    # example). Trying to do that would result in an error. But still
    # it would be nice to have a report about them too. If the package
    # didn't show up in the report for coreos-devel/board-packages
    # metapackage, we generate another one for the package. The result
    # will be a single report with possible duplicates, so the
    # anything that processes the report needs to take this into
    # account.
    #
    # Hopefully the duplicates will be actual duplicates, so nothing
    # that simple "sort -u" would not be able to handle. If we get
    # multiple versions for a single slot of a package in a report,
    # then we will need to revisit this code.

    # First, gather packages from the extra_sysexts.sh file - we will
    # source only a part of extra_sysexts.sh that defines the
    # EXTRA_SYSEXTS variable.
    local -i line_idx
    line_idx=$(grep --line-regexp --fixed-strings --line-number --max-count=1 --regexp=')' build_library/extra_sysexts.sh | cut --fields=1 --delimiter=':')

    local -a EXTRA_SYSEXTS
    source <(head --lines=${line_idx} build_library/extra_sysexts.sh)

    # Get sysext packages only if they are valid for the passed
    # architecture.
    local -A sysext_pkgs_set=()
    local entry name pkgs_csv uses_csv arches_csv ok_arch ok pkg
    local -a arches pkgs
    for entry in "${EXTRA_SYSEXTS[@]}"; do
        # The "uses" field has spaces, so turn them into commas, so we
        # can turn pipes into spaces and make a use of read for entire
        # entry.
        entry=${entry// /,}
        entry=${entry//|/ }
        read -r name pkgs_csv uses_csv arches_csv <<<"${entry}"

        ok=x
        if [[ -n ${arches_csv} ]]; then
            ok=
            read -r -a arches <<<"${arches_csv//,/ }"
            for ok_arch in "${arches[@]}"; do
                if [[ ${ok_arch} = "${arch}" ]]; then
                    ok=x
                    break
                fi
            done
        fi
        if [[ -z ${ok} ]]; then
            continue
        fi
        read -r -a pkgs <<<"${pkgs_csv//,/ }"
        for pkg in "${pkgs[@]}"; do
            sysext_pkgs_set["${pkg}"]=x
        done
    done

    # Do the check if the package was already in the report. If not,
    # generate another one.
    local slot stripped_escaped_pkg do_emerge escaped_slot
    for pkg in "${!sysext_pkgs_set[@]}"; do
        # strip possible slot information in package name
        stripped_escaped_pkg=${pkg%:*}
        slot=''
        if [[ ${stripped_escaped_pkg} != "${pkg}" ]]; then
            slot=${pkg##*:}
        fi
        # the only allowed character in category that is also a
        # special character in regexp is a dot; there are no allowed
        # characters in package name that are special characters in
        # regexps; thus we escape all the dots only
        stripped_escaped_pkg=${stripped_escaped_pkg//./'\.'}
        do_emerge=
        if [[ -z ${slot} ]]; then
            if ! grep -q -e '^\[[^]]*\]\s*'"${stripped_escaped_pkg}"'\s*' "${output_file}"; then
                do_emerge=x
            fi
        else
            # bah, a more complicated regexp to see if the package
            # name with the specific slot was listed
            #
            # a slot is similar to a category with regard to special
            # regexp characters - we escape only dots
            escaped_slot=${slot//./'\.'}
            if ! grep -q -e '^\[[^]]*\]\s*'"${stripped_escaped_pkg}"'\s*\[[^] ]*:'"${escaped_slot}"'::' "${output_file}"; then
                do_emerge=x
            fi
        fi
        if [[ -n ${do_emerge} ]]; then
            emerge_pretend "${root}" "${pkg}"
        fi
    done
    rm -f "${output_file}"
    revert_crossdev_stuff "${root}"
    revert_crossdev_stuff /
}

# Set the directory where the emerge output and the results of
# processing it will be stored. EO stands for "emerge output"
#
# Params:
#
# 1 - directory path
function set_eo() {
    local dir=${1}; shift
    # rest are architectures

    declare -g EGENCACHE_W="${dir}/egencache-warnings"
    declare -g SDK_EO="${dir}/sdk-emerge-output"
    declare -g SDK_EO_F="${SDK_EO}-filtered"
    declare -g SDK_EO_W="${SDK_EO}-warnings"
    declare -g SDK_EO_J="${SDK_EO}-junk"

    local arch
    local board_eo
    for arch; do
        board_eo=${dir}/${arch}-board-emerge-output
        declare -g "${arch^^}_BOARD_EO=${board_eo}"
        declare -g "${arch^^}_BOARD_EO_F=${board_eo}-filtered"
        declare -g "${arch^^}_BOARD_EO_W=${board_eo}-warnings"
        declare -g "${arch^^}_BOARD_EO_J=${board_eo}-junk"
    done
}

# JSON output would be more verbose, but probably would not require
# these abominations below. But, alas, emerge doesn't have that yet.

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

# Filters sdk reports to get the package information.
function filter_sdk_eo() {
    cat "${SDK_EO}" | xgrep -e "${FULL_LINE_RE}"
}

# Filters board reports for a given arch to get the package
# information.
#
# Params:
#
# 1 - architecture
function filter_board_eo() {
    local arch name
    arch=${1}; shift
    name=${arch^^}_BOARD_EO

    # Replace ${arch}-usr in the output with a generic word BOARD.
    cat "${!name}"  | \
        xgrep -e "${FULL_LINE_RE}" | \
        sed -e "s#/build/${arch}-usr/#/build/BOARD/#"
}

# Filters sdk reports to get anything but the package information
# (i.e. junk).
function junk_sdk_eo() {
    cat "${SDK_EO}" | xgrep -v -e "${FULL_LINE_RE}"
}

# Filters board reports to get anything but the package information
# (i.e. junk).
function junk_board_eo() {
    local arch name
    arch=${1}; shift
    name=${arch^^}_BOARD_EO

    cat "${!name}" | xgrep -v -e "${FULL_LINE_RE}"
}

# More regexp-like abominations follow.

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

# Applies some sed filter over the SDK emerge output. Results are
# printed.
#
# Params:
#
# @ - parameters passed to sed
function packages_for_sdk() {
    cat "${SDK_EO_F}" | sed "${@}" | sort -u
}

# Applies some sed filter over the board emerge output. Results are
# printed.
#
# Params:
#
# @ - parameters passed to sed
function packages_for_board() {
    local arch=${1}; shift
    # rest goes to sed

    local name=${arch^^}_BOARD_EO_F

    sed "${@}" "${!name}" | sort -u
}

# Prints package name, slot and version information for SDK.
function versions_sdk() {
    local -a sed_opts
    sed_opts=(
        "${PKG_VER_SLOT_SED_FILTERS[@]}"
    )
    packages_for_sdk "${sed_opts[@]}"
}

# Prints package name, slot, version and key-values information for
# SDK. Key-values may be something like USE="foo bar -baz".
function versions_sdk_with_key_values() {
    local -a sed_opts
    sed_opts=(
        "${PKG_VER_SLOT_KV_SED_FILTERS[@]}"
    )
    packages_for_sdk "${sed_opts[@]}"
}

# Prints package name, slot and version information for board.
function versions_board() {
    local arch=${1}; shift
    local -a sed_opts
    sed_opts=(
        -e '/to \/build\/BOARD\// ! d'
        "${PKG_VER_SLOT_SED_FILTERS[@]}"
    )
    packages_for_board "${arch}" "${sed_opts[@]}"
}

# Prints package name, slot, version and key-values information for
# build dependencies of board. Key-values may be something like
# USE="foo bar -baz".
function board_bdeps() {
    local arch=${1}; shift
    local -a sed_opts
    sed_opts=(
        -e '/to \/build\/BOARD\// d'
        "${PKG_VER_SLOT_KV_SED_FILTERS[@]}"
    )
    packages_for_board "${arch}" "${sed_opts[@]}"
}

# Print package name and source repository names information for SDK.
function package_sources_sdk() {
    local -a sed_opts
    sed_opts=(
        "${PKG_REPO_SED_FILTERS[@]}"
    )
    packages_for_sdk "${sed_opts[@]}"
}

# Print package name and source repository names information for
# board.
function package_sources_board() {
    local arch=${1}; shift
    local -a sed_opts
    sed_opts=(
        "${PKG_REPO_SED_FILTERS[@]}"
    )
    packages_for_board "${arch}" "${sed_opts[@]}"
}

# Checks if no errors were produced by emerge when generating
# reports. It is assumed that emerge will print a line with "ERROR" in
# it to denote a failure.
function ensure_no_errors() {
    local -a files=( "${SDK_EO_W}" )
    local arch name

    for arch; do
        name=${arch^^}_BOARD_EO_W
        files+=( "${!name}" )
    done

    if grep --quiet --fixed-strings 'ERROR' "${files[@]}"; then
        fail "there are errors in emerge output warnings files"
    fi
}

# Stores a path to a package.provided file inside the given root
# filesystem portage configuration. Mostly used to ignore
# cross-toolchains.
#
# Params:
#
# 1 - path to root filesystem with the portage configuration
# 2 - name of a variable where the path will be stored
function get_provided_file() {
    local root path_var_name
    root=${1}; shift
    path_var_name=${1}; shift
    local -n path_ref="${path_var_name}"

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
# Params:
#
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
    env --chdir="${crossdev_repo_path}" find . -type l | \
        cut -d/ -f2-3 | \
        sed -e 's/$/-9999/' | \
        sudo tee "${ics_path}" >/dev/null
}

# Reverts effects of the ignore_crossdev_stuff function.
#
# Params:
#
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

# Checks if the expected reports were generated by emerge.
function ensure_valid_reports() {
    local -a files=( "${SDK_EO_F}" )
    local arch name

    for arch; do
        name=${arch^^}_BOARD_EO_F
        files+=( "${!name}" )
    done

    local file
    for file in "${files[@]}"; do
        if [[ ! -s ${file} ]]; then
            fail "report files are missing or are empty"
        fi
    done
}

# Drops the empty warning files in given directory.
#
# Params:
#
# 1 - path to the directory
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

function generate_cache_for() {
    local repo=${1}; shift

    local -i gcf_num_proc
    local load_avg
    get_num_proc gcf_num_proc
    load_avg=$(bc <<< "${gcf_num_proc} * 0.75")
    egencache --repo "${repo}" --jobs="${gcf_num_proc}" --load-average="${load_avg}" --update
}

function copy_cache_to_reports() {
    local repo=${1}; shift
    local reports_dir=${1}; shift

    local repo_dir
    repo_dir=$(portageq get_repo_path / "${repo}")
    cp -a "${repo_dir}/metadata/md5-cache" "${reports_dir}/${repo}-cache"
}

fi
