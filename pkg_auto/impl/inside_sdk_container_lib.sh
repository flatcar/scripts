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
# @ - packages and metapackages to get the deps from, optionally
#     followed by double dash and use flags
function emerge_pretend() {
    local root=${1}; shift
    local -a pkgs=()
    local arg
    local -i count=0

    for arg; do
        ((++count))
        if [[ ${arg} == '--' ]]; then
            break
        fi
        pkgs+=( "${arg}" )
    done
    shift ${count}
    # rest are uses, if any

    printf '%s\n' \
           "Invoking emerge" \
           "ROOT: ${root}" \
           "USE: ${*}" \
           "packages: ${pkgs[*]}"

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
    if [[ ${#} -gt 0 ]]; then
        printf 'actual command: %s\n\n\n' "USE=\"${*}\" emerge ${emerge_opts[*]} ${pkgs[*]}"
    else
        printf 'actual command: %s\n\n\n' "emerge ${emerge_opts[*]} ${pkgs[*]}"
    fi
    if [[ ${#} -gt 0 ]]; then
        USE="${*}" emerge "${emerge_opts[@]}" "${pkgs[@]}" || rv=${?}
    else
        emerge "${emerge_opts[@]}" "${pkgs[@]}" || rv=${?}
    fi
    printf 'exit status: %d\n\n\n' "${rv}"
    if [[ ${rv} -ne 0 ]]; then
        echo "WARNING: emerge exited with status ${rv}" >&2
    fi
}

function create_fake_roots_for_other_sdks() {
    local fake_roots_dir=${1}; shift
    # rest are arches

    local make_profile current_arch
    make_profile=$(realpath /etc/portage/make.profile)
    if [[ ${make_profile} != */sdk ]]; then
        fail "unexpected SDK profile: ${make_profile}"
    fi
    current_arch=${make_profile%/sdk}
    current_arch=${current_arch##*/}
    local found='' arch
    local -a other_arches=()
    for arch; do
        if [[ ${arch} = "${current_arch}" ]]; then
            found=x
        else
            other_arches+=( "${arch}" )
        fi
    done
    if [[ -z ${found} ]]; then
        fail "architecture ${current_arch} taken from profile ${make_profile} does not match any of the passed architectures ${@@Q}"
    fi
    ln -sf / "${fake_roots_dir}/${current_arch}"
    local other_profile link target
    local -a links
    for arch in "${other_arches[@]}"; do
        other_profile=${make_profile#"/${current_arch}/sdk"}
        other_profile+=${arch}/sdk
        mkdir -p "${fake_roots_dir}/${arch}/etc"
        cp -a /etc/portage "${fake_roots_dir}/${arch}/etc/portage"
        # rewire symlinks
        mapfile -t -d '' links < <(find /etc/portage -type l -printf '%P\0')
        for link in "${links[@]}"; do
            target=$(realpath "/etc/portage/${link}")
            ln -sfr "${target}" "${fake_roots_dir}/${arch}/etc/portage/${link}"
        done
        # but rewire make.profile to actual SDK profile for the arch
        rm -f "${fake_roots_dir}/${arch}/etc/portage/make.profile"
        ln -sfr "${other_profile}" "${fake_roots_dir}/${arch}/etc/portage/make.profile"
    done
}

function ensure_top_package_versions_are_equal() {
    # Rust and binutils packages are annoying - they are both slotted
    # and emerge often insists on keeping the old version instead of
    # updating to the new version with a different slot. We can force
    # emerge to actually update if we tell it to do it explicitly. So
    # here we do some equeries to find a version and a slot of the
    # package that is stable on at least one supported architecture.
    local debug=''
    local -a debug_args=()
    if [[ ${1} = '-d' ]]; then
        debug=x; shift
        debug_args=( '-d' )
    fi
    local -n sdk_extra_pkgs_ref=${1}; shift
    local -n board_extra_pkgs_ref=${1}; shift
    local -n accept_keywords_to_add_ref=${1}; shift

    local fake_sdk_roots
    fake_sdk_roots=$(mktemp --directory)
    create_fake_roots_for_other_sdks "${fake_sdk_roots}" "${@}"
    local etpvae_slot etpvae_version etpvae_needs_accept_keywords arch
    local accept_keywords_file=${PKG_AUTO_DIR}/../sdk_container/src/third_party/coreos-overlay/profiles/coreos/base/package.accept_keywords

    local rust_slot='' rust_version='' rust_needs_accept_keywords=''
    for arch; do
        etpvae_slot=''
        etpvae_version=''
        etpvae_needs_accept_keywords=''
        equery_for_stable_package "${debug_args[@]}" "${fake_sdk_roots}/${arch}" 'dev-lang/rust' \
                                  etpvae_slot etpvae_version etpvae_needs_accept_keywords "${@}"
        if [[ -z ${rust_slot} ]]; then
            rust_slot=${etpvae_slot}
        elif [[ ${rust_slot} != "${etpvae_slot}" ]]; then
            fail "inconsistent rust slot information, expected ${rust_slot}, but for ${arch} got ${etpvae_slot}"
        fi
        if [[ -z ${rust_version} ]]; then
            rust_version=${etpvae_version}
        elif [[ ${rust_version} != "${etpvae_version}" ]]; then
            fail "inconsistent rust version information, expected ${rust_version}, but for ${arch} got ${etpvae_version}"
        fi
        if [[ -n ${etpvae_needs_accept_keywords} ]]; then
            rust_needs_accept_keywords=x
        fi
    done
    if [[ -n ${rust_needs_accept_keywords} ]]; then
        echo "=dev-lang/rust-${rust_version}" >>"${accept_keywords_file}"
        accept_keywords_to_add_ref+=( "dev-lang/rust ${rust_version}" )
    fi
    sdk_extra_pkgs_ref+=( "dev-lang/rust:${rust_slot}" )

    local binutils_slot='' binutils_version='' binutils_needs_accept_keywords=''
    for arch; do
        etpvae_slot=''
        etpvae_version=''
        etpvae_needs_accept_keywords=''
        equery_for_stable_package "${debug_args[@]}" "/build/${arch}-usr" 'sys-devel/binutils' \
                                  etpvae_slot etpvae_version etpvae_needs_accept_keywords "${@}"
        if [[ -z ${binutils_slot} ]]; then
            binutils_slot=${etpvae_slot}
        elif [[ ${binutils_slot} != "${etpvae_slot}" ]]; then
            fail "inconsistent binutils slot information, expected ${binutils_slot}, but for ${arch} got ${etpvae_slot}"
        fi
        if [[ -z ${binutils_version} ]]; then
            binutils_version=${etpvae_version}
        elif [[ ${binutils_version} != "${etpvae_version}" ]]; then
            fail "inconsistent binutils version information, expected ${binutils_version}, but for ${arch} got ${etpvae_version}"
        fi
        if [[ -n ${etpvae_needs_accept_keywords} ]]; then
            binutils_needs_accept_keywords=x
        fi
    done
    if [[ -n ${binutils_needs_accept_keywords} ]]; then
        echo "=sys-devel/binutils-${binutils_version}" >>"${accept_keywords_file}"
        accept_keywords_to_add_ref+=( "sys-devel/binutils ${binutils_version}" )
    fi
    board_extra_pkgs_ref+=( "sys-devel/binutils:${binutils_slot}" )
}

function equery_for_stable_package() {
    local debug=''
    if [[ ${1} = '-d' ]]; then
        debug=x; shift
    fi
    local root=${1}; shift
    local pkg=${1}; shift
    local -n slot_ref=${1}; shift
    local -n version_ref=${1}; shift
    local -n needs_accept_keywords_ref=${1}; shift
    # rest are architectures

    if [[ ${#} -eq 0 ]]; then
        fail "need to pass at least one architecture"
    fi

    local -x PORTAGE_CONFIGROOT=${root}
    local -x SYSROOT=${root}
    local -x ROOT=${root}

    # generated pre-filter awk code is something like the following:
    #
    # {
    #   if ((NF >= 9) && ($1 != "|")) {
    #     slot = $8
    #     if (slot == "|") {
    #       slot = last_slot
    #     }
    #     last_slot = slot
    #     print $1, slot, $3, $4
    #   }
    # }
    #
    # generated awk code is something like following:
    #
    # {
    #   if (substr($1, 1, 3) != "[M]" && ($3 == "+" || $4 == "+")) {
    #     if (substr($1, 1, 3) == "[I]") {
    #       v = substr($1, 4)
    #     } else {
    #       v = $1
    #     }
    #     print v, $2, $3, $4; exit 0
    #   }
    # }
    local equery_arches='' awk_filter_code='' awk_code='' awk_print_code='' awk_eq_code=''
    local -i awk_arch_idx=3 awk_slot_idx

    local arch
    for arch; do
        if [[ -z ${equery_arches} ]]; then
            equery_arches=${arch}
        else
            equery_arches+=",${arch}"
        fi
        if [[ awk_arch_idx -gt 3 ]]; then
            awk_eq_code+=' || '
        fi
        awk_eq_code+='$'
        awk_eq_code+=${awk_arch_idx}
        awk_eq_code+=' == "+"'
        awk_print_code+=', $'
        awk_print_code+=${awk_arch_idx}
        ((++awk_arch_idx))
    done
    awk_slot_idx=$((awk_arch_idx + 3))
    awk_filter_code+='{ if ((NF >= 9) && ($1 != "|")) { slot = $'
    awk_filter_code+=${awk_slot_idx}
    awk_filter_code+='; if (slot == "|") { slot = last_slot }; last_slot = slot; print $1, slot'
    awk_filter_code+=${awk_print_code}
    awk_filter_code+=' } }'
    awk_code+='{ if (substr($1, 0, 3) != "[M]" && ('
    awk_code+=${awk_eq_code}
    awk_code+=')) { if (substr($1, 1, 3) == "[I]") { v = substr($1, 4) } else { v = $1 }; print v, $2'
    awk_code+=${awk_print_code}
    awk_code+='; exit 0 } }'
    debug_print "${debug}" 'awk filter code used:' "${awk_filter_code}"
    debug_print "${debug}" 'awk code used:' "${awk_code}"

    local equery_output awk_output
    equery_output=$(equery --no-color keywords --overlays --arch "${equery_arches}" "${pkg}")
    debug_print "${debug}" 'equery output' "${equery_output}"
    awk_output=$(awk "${awk_filter_code}" <<<"${equery_output}" | tac | awk "${awk_code}")
    local -a output_fields
    read -r -a output_fields <<<"${awk_output}"
    local pkg_version=${output_fields[0]}
    local pkg_slot=${output_fields[1]}
    output_fields=( "${output_fields[@]:2}" )
    debug_print "${debug}" "found slot for ${pkg}: ${pkg_slot} (version: ${pkg_version})"
    local -i marker_idx=0
    if [[ ${#} -ne ${#output_fields[@]} ]]; then
        fail "inconsistent architecture count, given ${#}, and ${#output_fields[@]} through equery"
    fi
    needs_accept_keywords_ref=''
    for ((marker_idx = 0; marker_idx < ${#}; ++marker_idx)); do
        if [[ ${output_fields[marker_idx]} != '+' ]]; then
            needs_accept_keywords_ref=x
        fi
    done
    slot_ref=${pkg_slot}
    version_ref=${pkg_version}
}

# Gets package list for SDK.
#
# Params:
#
# ? - optional -d flag for debugging output
# 1 - path to emerge output file
# # - extra packages
function package_info_for_sdk() {
    local debug=''
    local -a debug_args=()
    if [[ ${1} = '-d' ]]; then
        debug=x; shift
        debug_args+=(-d)
    fi
    local output_file=${1}; shift
    # rest are extra packages
    local root=/

    ignore_crossdev_stuff "${root}"
    # stage4 build of SDK builds coreos-devel/sdk-depends, fsscript
    # pulls in cross toolchains with crossdev (which we have just
    # ignored) and dev-lang/rust
    emerge_pretend "${root}" coreos-devel/sdk-depends "${@}" >"${output_file}"
    revert_crossdev_stuff "${root}"
}

# Gets package list for board of a given architecture.
#
# Params:
#
# ? - optional -d flag for debugging output
# 1 - architecture
# 2 - path to emerge output file
# # - extra packages
function package_info_for_board() {
    local debug=''
    local -a debug_args=()
    if [[ ${1} = '-d' ]]; then
        debug=x; shift
        debug_args+=(-d)
    fi
    local arch=${1}; shift
    local output_file=${1}; shift

    local root="/build/${arch}-usr" debug_output_file='/dev/null'

    if [[ -n ${debug} ]]; then
        debug_output_file=${output_file}.debug.main
    fi

    local -a oem_descriptors
    mapfile -t oem_descriptors < <(
        source build_library/oem_sysexts.sh
        local -a oem_descs=()
        get_oem_sysext_matrix "${arch}" oem_descs
        printf '%s\n' "${oem_descs[@]}"
    )
    local -a fields oem_pkgs=()
    for entry in "${oem_descriptors[@]}"; do
        read -r -a fields <<<"${entry//|/ }"
        oem_pkgs+=("${fields[1]}")
    done

    local tmp_emerge_output
    tmp_emerge_output=$(mktemp)

    local -a base_pkgs=(
        coreos-devel/board-packages
        "${@}"
    )

    # Ignore crossdev stuff in both SDK root and board root - emerge
    # may query SDK stuff for the board packages.
    ignore_crossdev_stuff /
    ignore_crossdev_stuff "${root}"
    local pkg='coreos-devel/board-packages'
    debug_print "${debug}" "packages ${base_pkgs[*]} ${oem_pkgs[*]}"
    emerge_pretend "${root}" "${base_pkgs[@]}" "${oem_pkgs[@]}" | tee "${debug_output_file}" "${tmp_emerge_output}" >"${output_file}"

    return 0

    local -a lines=()
    mapfile -t lines < <(
        cat "${tmp_emerge_output}" | \
            xgrep -e "${FULL_LINE_RE}" | \
            sed -e "s#/build/${arch}-usr/#/build/BOARD/#" | \
            sed \
                "${BOARD_ONLY_PKGS[@]}" \
                "${PKG_VER_SLOT_SED_FILTERS[@]}" | \
            sort -u)

    sudo rm -f "${root}${pkg_mask_file}" "${root}${pkg_unmask_file}" "${tmp_emerge_output}"

    local board_pkg_mask_file=${root}/etc/portage/package.mask/pkg-auto-board.conf
    local board_pkg_unmask_file=${root}/etc/portage/package.unmask/pkg-auto-board.conf
    local line tmp_mask_file tmp_unmask_file
    tmp_mask_file=$(mktemp)
    tmp_unmask_file=$(mktemp)
    for line in "${lines[@]}"; do
        qpkg=${line%% *}
        version=${line#* }
        version=${version%%:*}
        echo "${qpkg}" >>"${tmp_mask_file}"
        echo "=${qpkg}-${version}" >>"${tmp_unmask_file}"
    done
    sudo mv "${tmp_mask_file}" "${board_pkg_mask_file}"
    sudo mv "${tmp_unmask_file}" "${board_pkg_unmask_file}"

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
    # architecture and are missing from the reports.
    local -A sysext_pkgs_csv_to_uses_csv_flags_map=()
    local entry name pkgs_csv uses_csv arches_csv ok_arch ok
    local -a arches pkgs uses
    local slot stripped_escaped_pkg do_emerge escaped_slot
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
        do_emerge=''
        if [[ -n ${uses_csv} ]]; then
            # Nevermind if packages are already in report - do a
            # report anyway, with custom USE flags.
            #
            # This has potential to be messy, though, by having
            # packages with different USE flags in reports…
            do_emerge=x
        else
            # Check if any of the packages was is missing from the
            # report. If so, we will generate another one for this set
            # of packages.
            read -r -a pkgs <<<"${pkgs_csv//,/ }"
            for pkg in "${pkgs[@]}"; do
                # Strip possible slot information in package name.
                stripped_escaped_pkg=${pkg%:*}
                slot=''
                if [[ ${stripped_escaped_pkg} != "${pkg}" ]]; then
                    slot=${pkg##*:}
                fi
                # The only allowed character in category that is also
                # a special character in regexp is a dot. There are no
                # allowed characters in package name that are special
                # characters in regexps. Thus we escape all the dots
                # only.
                stripped_escaped_pkg=${stripped_escaped_pkg//./'\.'}
                if [[ -z ${slot} ]]; then
                    if ! grep -q -e '^\[[^]]*\]\s*'"${stripped_escaped_pkg}"'\s*' "${output_file}"; then
                        do_emerge=x
                        break
                    fi
                else
                    # Bah, a more complicated regexp to see if the
                    # package name with the specific slot was listed.
                    #
                    # A slot is similar to a category with regard to
                    # special regexp characters - we escape only dots.
                    escaped_slot=${slot//./'\.'}
                    if ! grep -q -e '^\[[^]]*\]\s*'"${stripped_escaped_pkg}"'\s*\[[^] ]*:'"${escaped_slot}"'::' "${output_file}"; then
                        do_emerge=x
                        break
                    fi
                fi
            done
        fi
        if [[ -n ${do_emerge} ]]; then
            sysext_pkgs_csv_to_uses_csv_flags_map["${pkgs_csv}"]=${uses_csv}
        fi
    done

    # Generate additional reports for the yet unreported sysext
    # packages.
    local dbg_suffix
    for pkgs_csv in "${!sysext_pkgs_csv_to_uses_csv_flags_map[@]}"; do
        uses_csv=${sysext_pkgs_csv_to_uses_csv_flags_map["${pkgs_csv}"]}
        if [[ -n ${debug} ]]; then
            dbg_suffix=${pkgs_csv//\//-}
            if [[ -n ${uses_csv} ]]; then
                dbg_suffix+='.uses.'
                dbg_suffix+=${uses_csv}
            fi
            debug_output_file=${output_file}.debug.pkgs.${dbg_suffix}
        fi
        read -r -a pkgs <<<"${pkgs_csv//,/ }"
        read -r -a uses <<<"${uses_csv//,/ }"
        debug_print "${debug}" "packages ${pkgs[*]} with USE ${uses[*]}"
        emerge_pretend "${root}" "${base_pkgs[@]}" "${pkgs[@]}" -- "${uses[@]}" | tee "${debug_output_file}" >>"${output_file}"
    done

    sudo rm -f "${board_pkg_mask_file}" "${board_pkg_unmask_file}"
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
VER_SLOT_REPO_NOCAPTURE_RE='\[[^]]\+::[^]]\+]' # 0 groups
VER_SLOT_REPO_RE='\[\([^]]\+\)::\([^]]\+\)]' # 2 groups
TARGET_NOCAPTURE_RE='to[[:space:]]\+[^[:space:]]\+' # 0 groups
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

BOARD_ONLY_PKGS=(
    -e '/to \/build\/BOARD\// ! d'
)

BOARD_BDEPS_ONLY_PKGS=(
    -e '/to \/build\/BOARD\// d'
)

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
    -e "s/${STATUS_RE}${SPACES_RE}\(${PACKAGE_NAME_RE}\)${SPACES_RE}${VER_SLOT_REPO_RE}\(${SPACES_RE}${VER_SLOT_REPO_NOCAPTURE_RE}\)\?\(${SPACES_RE}${TARGET_NOCAPTURE_RE}\)\?\(${SPACES_RE}\(${KEYVALS_RE}\)\)\?${SPACES_RE}${SIZE_RE}\$/\1 \2 \7/"
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

# Prints package name, version and slot information for SDK.
function versions_sdk() {
    local -a sed_opts
    sed_opts=(
        "${PKG_VER_SLOT_SED_FILTERS[@]}"
    )
    packages_for_sdk "${sed_opts[@]}"
}

# Prints package name, version, slot and key-values information for
# SDK. Key-values may be something like USE="foo bar -baz".
function versions_sdk_with_key_values() {
    local -a sed_opts
    sed_opts=(
        "${PKG_VER_SLOT_KV_SED_FILTERS[@]}"
    )
    packages_for_sdk "${sed_opts[@]}"
}

# Prints package name, version and slot information for board.
function versions_board() {
    local arch=${1}; shift
    local -a sed_opts
    sed_opts=(
        "${BOARD_ONLY_PKGS[@]}"
        "${PKG_VER_SLOT_SED_FILTERS[@]}"
    )
    packages_for_board "${arch}" "${sed_opts[@]}"
}

# Prints package name, version, slot and key-values information for
# board. Key-values may be something like USE="foo bar -baz".
function versions_board_with_key_values() {
    local arch=${1}; shift
    local -a sed_opts
    sed_opts=(
        "${BOARD_ONLY_PKGS[@]}"
        "${PKG_VER_SLOT_KV_SED_FILTERS[@]}"
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
        "${BOARD_BDEPS_ONLY_PKGS[@]}"
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
# 2 - ID of the crossdev repository (optional, defaults to crossdev)
function ignore_crossdev_stuff() {
    local root crossdev_repo_id
    root=${1}; shift
    if [[ ${#} -gt 0 ]]; then
        crossdev_repo_id=${1}; shift
    else
        local -a repos
        local repo
        mapfile -t -d ' ' repos < <(portageq get_repos "${root}")
        for repo in "${repos[@]}"; do
            if [[ ${repo} = *crossdev* ]]; then
                crossdev_repo_id=${repo}
                break
            fi
        done
        if [[ -z ${crossdev_repo_id} ]]; then
            crossdev_repo_id=crossdev
        fi
    fi

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

# Generates the md5-metadata cache for the passed ebuid repository.
# The generated cache is stored within the repository
#
# Params:
#
# ? - optional -d flag for debugging output
# 1 - repository name
function generate_cache_for() {
    local debug=''
    local pmaint_args=()
    if [[ ${1} = '-d' ]]; then
        debug=x; shift
        pmaint_args+=(--debug --verbose)
    else
        pmaint_args+=(-q)
    fi
    local repo=${1}; shift

    #local -i gcf_num_proc
    #local load_avg
    #get_num_proc gcf_num_proc
    #load_avg=$(bc <<< "${gcf_num_proc} * 0.75")
    #debug_print "${debug}" "using ${gcf_num_proc} jobs with ${load_avg} load average"
    #egencache --repo "${repo}" --jobs="${gcf_num_proc}" --load-average="${load_avg}" --update
    pmaint regen "${repo}"
}

# Copies the generated md5-metadata cache into reports directory.
#
# Params:
#
# ? - optional -d flag for debugging output
# 1 - repository name
# 2 - reports directory
function copy_cache_to_reports() {
    local debug=''
    if [[ ${1} = '-d' ]]; then
        debug=x; shift
    fi
    local repo=${1}; shift
    local reports_dir=${1}; shift

    local repo_dir
    repo_dir=$(portageq get_repo_path / "${repo}")
    debug_print "${debug}" "repo dir at ${repo_dir}"
    cp -a "${repo_dir}/metadata/md5-cache" "${reports_dir}/${repo}-cache"
}

# Prints if first parameter is not empty. Meant to be used like:
#
# debug_print "${debug}" "some debug message"
#
# params:
#
# 1 - debug marker - the function will be no op if this is empty
# @ - messages to be printed
function debug_print() {
    if [[ -z ${1} ]]; then return 0; fi
    shift
    printf '%s\n' "${@}"
}

fi
