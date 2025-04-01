#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# image_changes() should be called w/ the positional INPUT parameters below.

# OS image differences display stub.
#   This script will display the differences between the last released image and the currently built one.
#
# PREREQUISITES:
#
#   1. Artifacts describing the built image (kernel config, contents, packages, etc.) must be present in build cache server.
#   2. Scripts repo version tag of OS image version to be built is available and checked out.
#
# INPUT:
#
#   1. Architecture (ARCH) of the TARGET OS image ("arm64", "amd64").
#   2. What to compare against, must be either "last-release" or "last-nightly".
#
# OPTIONAL INPUT:
#
#   (none)
#
# OUTPUT:
#
#   1. Currently the script prints the image differences compared to the last release and the changelog for the release notes but doesn't store it yet in the buildcache.

# Run a subshell, so the traps, environment changes and global
# variables are not spilled into the caller.
function image_changes() (
    set -euo pipefail
    local arch what

    arch=${1}; shift
    # make nightly and release from last-nightly and last-release, respectively
    mode=${1#last-}; shift

    local fbs_repo='../flatcar-build-scripts'
    rm -rf "${fbs_repo}"
    git clone \
        --depth 1 \
        --single-branch \
        "https://github.com/flatcar/flatcar-build-scripts" \
        "${fbs_repo}"
    if [[ -z "${BUILDCACHE_SERVER:-}" ]]; then
        local BUILDCACHE_SERVER
        BUILDCACHE_SERVER=$(source ci-automation/ci-config.env; echo "${BUILDCACHE_SERVER}")
    fi
    local version
    version=$(source sdk_container/.repo/manifests/version.txt; echo "${FLATCAR_VERSION}")
    echo "Image URL: http://${BUILDCACHE_SERVER}/images/${arch}/${version}/flatcar_production_image.bin.bz2"
    echo
    run_image_changes_job "${arch}" "${mode}" '-' "${fbs_repo}" ricj_callback
)
# --

# Callback invoked by run_image_changes_job, read its docs to learn
# about the details about the callback.
function ricj_callback() {
    local ic_head_tag version
    head_git_tag . ic_head_tag
    version=$(source sdk_container/.repo/manifests/version.txt; echo "${FLATCAR_VERSION}")
    package_diff_env+=(
        "FROM_B=bincache"
        "BOARD_B=${arch}-usr"
        # CHANNEL_B is unused
    )
    package_diff_params+=(
        "${version}"
    )
    # Nothing to add to size changes env.
    size_changes_params+=(
        "bincache:${arch}:${version}"
    )
    show_changes_env+=(
        # Provide a python3 command for the CVE DB parsing
        "PATH=${PATH}:${PWD}/ci-automation/python-bin"
        # Override the default locations of repositories.
        "SCRIPTS_REPO=."
        "COREOS_OVERLAY_REPO=../coreos-overlay"
        "PORTAGE_STABLE_REPO=../portage-stable"
    )
    show_changes_params+=(
        # The show-changes script expects a tag name, so using git tag
        # here instead of the vernum variable.
        "NEW_VERSION=${ic_head_tag}"
    )
}
# --

# Runs the whole image changes job for given arch and mode. The report
# is written to the given file. The reports will be done using tools
# from the passed path to the flatcar build scripts repository. The
# parameters and environment of the tools should will be partially set
# up depending on mode, but the further setup should be done by the
# passed callback.
#
# The callback takes no parameters. It should assume that array
# variables 'package_diff_env', 'package_diff_params',
# 'size_changes_env', 'size_changes_params', 'show_changes_env' and
# 'show_changes_params' are already defined, so it can append
# necessary data into them.
#
# 1 - arch
# 2 - mode
# 3 - report file name ('-' for standard output)
# 4 - path to the flatcar-build-scripts repository
# 5 - name of a callback function
function run_image_changes_job() {
    arch=${1}; shift
    mode=${1}; shift
    report_file_name=${1}; shift
    fbs_repo=${1}; shift
    cb=${1}; shift

    case ${mode} in
        release|nightly)
            :
            ;;
        *)
            echo "invalid mode ${mode@Q}, expected 'nightly' or 'release'" >&2
            exit 1
            ;;
    esac

    local -a package_diff_env package_diff_params
    local -a size_changes_env size_changes_params
    local -a show_changes_env show_changes_params
    local version_description
    local -a var_names=(
        package_diff_env package_diff_params
        size_changes_env size_changes_params
        show_changes_env show_changes_params
        version_description
    )
    local git_tag_for_mode prepare_env_vars_and_params_for_mode
    git_tag_for_mode="git_tag_for_${mode}"
    prepare_env_vars_and_params_for_mode="prepare_env_vars_and_params_for_${mode}"

    local git_tag
    "${git_tag_for_mode}" . git_tag
    "${prepare_env_vars_and_params_for_mode}" "${arch}" "${git_tag}" "${var_names[@]}"

    # invoke callback that should append necessary info to env and params variables
    "${cb}"

    local -a oemids base_sysexts extra_sysexts
    get_oem_id_list . "${arch}" oemids
    get_base_sysext_list . base_sysexts
    get_extra_sysext_list . extra_sysexts
    generate_image_changes_report \
        "${version_description}" "${report_file_name}" "${fbs_repo}" \
        "${package_diff_env[@]}" --- "${package_diff_params[@]}" -- \
        "${size_changes_env[@]}" --- "${size_changes_params[@]}" -- \
        "${show_changes_env[@]}" --- "${show_changes_params[@]}" -- \
        "${oemids[@]}" -- "${base_sysexts[@]}" -- "${extra_sysexts[@]}"
}
# --

# Gets a git tag that can be passed to
# prepare_env_vars_and_params_for_release.
#
# 1 - scripts repo
# 2 - name of a variable to store the result in
function git_tag_for_release() {
    local scripts_repo git_tag_var_name
    scripts_repo=${1}; shift
    git_tag_var_name=${1}; shift

    head_git_tag "${scripts_repo}" "${git_tag_var_name}"

    local -n git_tag_ref="${git_tag_var_name}"
    local version_file version_id build_id minor_version channel
    if [[ ${git_tag_ref} = 'HEAD' ]]; then
        # Welp, we wanted to have something in form of
        # <channel>-<version_id>-<build_id>, fake something up from
        # version file. Figuring out the channel is a heuristic at
        # best.
        version_file="${scripts_repo}/sdk_container/.repo/manifests/version.txt"
        if [[ ! -e ${version_file} ]]; then
            echo "The scripts repo at '${scripts_repo}' is messed up, has no version file" >&2
            exit 1
        fi
        version_id=$(source "${version_file}"; printf '%s' "${FLATCAR_VERSION_ID}")
        build_id=$(source "${version_file}"; printf '%s' "${FLATCAR_BUILD_ID}")
        minor_version=${version_id#*.}
        minor_version=${minor_version%.*}
        case ${minor_version} in
            0)
                channel=alpha
                ;;
            1)
                channel=beta
                ;;
            2)
                channel=stable
                ;;
            3)
                channel=lts
                ;;
            *)
                channel=main
                ;;
        esac
        git_tag_ref="${channel}-${version_id}-${build_id}"
    fi
}

function head_git_tag() {
    local scripts_repo
    scripts_repo=${1}; shift
    local -n git_tag_ref="${1}"; shift

    git_tag_ref=$(git -C "${scripts_repo}" tag --points-at HEAD)
    if [[ -z ${git_tag_ref} ]]; then
        git_tag_ref='HEAD'
    fi
}

# Gets a git tag of a previous nightly that can be passed to
# prepare_env_vars_and_params_for_nightly.
#
# 1 - scripts repo
# 2 - name of a variable to store the result in
function git_tag_for_nightly() {
    local scripts_repo
    scripts_repo=${1}; shift
    local -n git_tag_ref="${1}"; shift

    local head_tag search_object
    head_tag=$(git -C "${scripts_repo}" tag --points-at HEAD)
    search_object='HEAD'
    if [[ ${head_tag} = *-nightly-* ]] && [[ ! ${head_tag} = *-INTERMEDIATE ]]; then
        # HEAD is a nightly, pick an earlier commit to avoid comparing with itself
        search_object='HEAD^'
    fi
    git_tag_ref=$(git -C "${scripts_repo}" describe --tags --abbrev=0 --match='*-nightly-*' --exclude='*-INTERMEDIATE' "${search_object}")
}

# Gets a list of OEMs that are using sysexts.
#
# 1 - scripts repo
# 2 - arch
# 3 - name of an array variable to store the result in
function get_oem_id_list() {
    local scripts_repo arch list_var_name
    scripts_repo=${1}; shift
    arch=${1}; shift
    list_var_name=${1}; shift

    local -a ebuilds=("${scripts_repo}/sdk_container/src/third_party/coreos-overlay/coreos-base/common-oem-files/common-oem-files-"*'.ebuild')
    if [[ ${#ebuilds[@]} -eq 0 ]] || [[ ! -e ${ebuilds[0]} ]]; then
        echo "No coreos-base/common-oem-files ebuilds?!" >&2
        exit 1
    fi

    # This defines local COMMON_OEMIDS, AMD64_ONLY_OEMIDS,
    # ARM64_ONLY_OEMIDS and OEMIDS variable. We don't use the last
    # one. Also defines global-by-default EAPI, which we make local
    # here to avoid making it global.
    local EAPI
    source "${ebuilds[0]}" flatcar-local-variables

    local -n arch_oemids_ref="${arch^^}_ONLY_OEMIDS"
    local all_oemids=(
        "${COMMON_OEMIDS[@]}"
        "${arch_oemids_ref[@]}"
    )

    mapfile -t "${list_var_name}" < <(printf '%s\n' "${all_oemids[@]}" | sort)
}

function get_base_sysext_list() {
    local scripts_repo=${1}; shift
    local -n list_var_ref=${1}; shift

    source "${scripts_repo}/ci-automation/base_sysexts.sh" 'local'

    list_var_ref=( "${ciabs_base_sysexts[@]%%|*}" )
}

function get_extra_sysext_list() {
    local scripts_repo=${1}; shift
    local -n list_var_ref=${1}; shift

    # defined in the file we source below
    local -a EXTRA_SYSEXTS
    source "${scripts_repo}/build_library/extra_sysexts.sh"

    list_var_ref=( "${EXTRA_SYSEXTS[@]%%|*}" )
}

# Generates reports with passed parameters. The report is redirected
# into the passed report file.
#
# 1 - version description (a free form string that describes a version of image that current version is compared against)
# 2 - report file (can be relative), '-' for standard output
# 3 - flatcar-build-scripts directory (can be relative, will be realpathed)
# @ - package-diff env vars --- package-diff version B param -- size-change-report.sh env vars --- size-change-report.sh spec B param -- show-changes env vars --- show-changes param overrides -- list of OEM ids -- list of base sysext names -- list of extra sysext names
#
# Example:
#
# generate_image_changes_report \\
#     'Alpha 3456.0.0' reports/images.txt ../flatcar-build-scripts .. \\
#     FROM_A=release BOARD_A=amd64-usr CHANNEL_A=alpha FROM_B=bincache BOARD_B=amd64-usr --- \\
#     3456.0.0 3478.0.0+my-changes -- \\
#     --- \\
#     release:amd64-usr:3456.0.0 bincache:amd64:3478.0.0+my-changes -- \\
#     "PATH=${PATH}:${PWD}/ci-automation/python-bin" --- \\
#     NEW_VERSION=main-3478.0.0-my-changes NEW_CHANNEL=alpha NEW_CHANNEL_PREV_VERSION=3456.0.0 OLD_CHANNEL=alpha OLD_VERSION='' -- \\
#     azure vmware -- containerd-flatcar docker-flatcar -- python podman zfs
function generate_image_changes_report() (
    set -euo pipefail

    local version_description=${1}; shift
    local report_output=${1}; shift
    local flatcar_build_scripts_repo=${1}; shift
    # rest is forwarded verbatim to print_image_reports

    local print_image_reports_invocation=(
        print_image_reports
        "${flatcar_build_scripts_repo}" "${version_description}" "${@}"
    )
    # Using "|| :" to avoid failing the job.
    if [[ ${report_output} = '-' ]]; then
        "${print_image_reports_invocation[@]}" || :
    else
        {
            "${print_image_reports_invocation[@]}" || :
        } >"${report_output}"
    fi
)
# --

# Prepares the tool parameters, so they compare against the last
# release relative to the git tag. The git tag should be in form of
# <channel>-<version id>-<build id>, which is the usual format used in
# scripts repo.
function prepare_env_vars_and_params_for_release() {
    local arch git_tag
    arch=${1}; shift
    git_tag=${1}; shift
    local -n package_diff_env_ref="${1}"; shift
    local -n package_diff_params_ref="${1}"; shift
    local -n size_changes_env_ref="${1}"; shift
    local -n size_changes_params_ref="${1}"; shift
    local -n show_changes_env_ref="${1}"; shift
    local -n show_changes_params_ref="${1}"; shift
    local -n version_description_ref="${1}"; shift

    local ppfr_channel ppfr_version_id ppfr_build_id ppfr_version ppfr_vernum
    split_tag "${git_tag}" ppfr_channel ppfr_version_id ppfr_build_id ppfr_version ppfr_vernum
    if [[ ${ppfr_channel} = 'main' ]]; then
        ppfr_channel='alpha'
    fi
    local board new_channel new_channel_prev_version channel_a version_a
    board="${arch}-usr"

    new_channel="${ppfr_channel}"
    if [[ ${new_channel} = 'lts' ]]; then
        new_channel_prev_version=$(lts_channel_version "${ppfr_version_id%%.*}" "${board}")
    else
        new_channel_prev_version=$(channel_version "${new_channel}" "${board}")
    fi
    channel_a=''
    version_a=''
    get_channel_a_and_version_a "${new_channel}" "${new_channel_prev_version}" "${ppfr_version}" "${board}" channel_a version_a
    package_diff_env_ref=(
        # For A.
        "FROM_A=release"
        "BOARD_A=${board}"
        "CHANNEL_A=${channel_a}"
    )
    package_diff_params_ref=(
        # For A.
        "${version_a}"
    )

    # Nothing to prepend to size_changes_env.
    size_changes_env_ref=()
    # First parts of the size-changes-report specs, the kind is
    # appended at call sites.
    size_changes_params_ref=(
        # For A.
        "release:${channel_a}:${board}:${version_a}"
    )

    # Nothing to prepend to show_changes_env.
    show_changes_env_ref=()
    show_changes_params=(
        "NEW_CHANNEL=${new_channel}"
        "NEW_CHANNEL_PREV_VERSION=${new_channel_prev_version}"
        # Channel transition stuff
        "OLD_CHANNEL=${channel_a}"
        "OLD_VERSION=${version_a}"
    )

    version_description_ref="${channel_a} ${version_a}"
}
# --

# Prepares the tool parameters, so they compare against the last
# nightly relative to the git tag. The git tag should be in form of
# <channel>-<version id>-<build id>, which is the usual format used in
# scripts repo.
function prepare_env_vars_and_params_for_nightly() {
    local arch git_tag
    arch=${1}; shift
    git_tag=${1}; shift
    local -n package_diff_env_ref="${1}"; shift
    local -n package_diff_params_ref="${1}"; shift
    local -n size_changes_env_ref="${1}"; shift
    local -n size_changes_params_ref="${1}"; shift
    local -n show_changes_env_ref="${1}"; shift
    local -n show_changes_params_ref="${1}"; shift
    local -n version_description_ref="${1}"; shift

    local board
    board="${arch}-usr"
    local ppfb_channel ppfb_version_id ppfb_build_id ppfb_version ppfb_vernum
    split_tag "${git_tag}" ppfb_channel ppfb_version_id ppfb_build_id ppfb_version ppfb_vernum

    package_diff_env_ref=(
        # For A.
        "FROM_A=bincache"
        "BOARD_A=${board}"
        # CHANNEL_A is unused.
    )
    package_diff_params_ref=(
        # For A.
        "${ppfb_version}"
    )

    # Nothing to prepend to size_changes_env.
    size_changes_env_ref=()
    # First parts of the size-changes-report specs, the kind is
    # appended at call sites.
    size_changes_params_ref=(
        # For A.
        "bincache:${arch}:${ppfb_version}"
    )

    # Nothing to prepend to show_changes_env.
    show_changes_env_ref=()
    show_changes_params=(
        "NEW_CHANNEL=${ppfb_channel}"
        "NEW_CHANNEL_PREV_VERSION=${ppfb_vernum}"
        # Channel transition stuff, we set the old channel to be the
        # same as the new channel to say that there was no channel
        # transition. Such would not make any sense here.
        "OLD_CHANNEL=${ppfb_channel}"
        "OLD_VERSION=${ppfb_vernum}"
    )

    version_description_ref="development version ${ppfb_channel} ${ppfb_version}"
}
# --

function split_tag() {
    local git_tag
    git_tag=${1}; shift
    local -n channel_ref=${1}; shift
    local -n version_id_ref=${1}; shift
    local -n build_id_ref=${1}; shift
    local -n version_ref=${1}; shift
    local -n vernum_ref=${1}; shift

    local channel version_id build_id version vernum
    channel=${git_tag%%-*}
    version_id=${git_tag#*-}
    version_id=${version_id%%-*}
    build_id=${git_tag#"${channel}-${version_id}"}
    if [[ -n ${build_id} ]]; then
        build_id=${build_id#-}
        version="${version_id}+${build_id}"
        vernum="${version_id}-${build_id}"
    else
        version="${version_id}"
        vernum="${version_id}"
    fi
    channel_ref=${channel}
    version_id_ref=${version_id}
    build_id_ref=${build_id}
    version_ref=${version}
    vernum_ref=${vernum}
}
# --

function get_channel_a_and_version_a() {
    local new_channel=${1}; shift
    local new_channel_prev_version=${1}; shift
    local new_channel_new_version=${1}; shift
    local board=${1}; shift
    local gcaava_channel_a_varname=${1}; shift
    local gcaava_version_a_varname=${1}; shift
    local -n gcaava_channel_a_ref="${gcaava_channel_a_varname}"
    local -n gcaava_version_a_ref="${gcaava_version_a_varname}"
    local major_a major_b channel version

    major_a=${new_channel_prev_version%%.*}
    major_b=${new_channel_new_version%%.*}
    # When the major version for the new channel is different, a transition has happened and we can find the previous release in the old channel
    if [[ ${major_a} != "${major_b}" ]]; then
        case ${new_channel} in
          lts)
            channel=stable
            ;;
          stable)
            channel=beta
            ;;
          *)
            channel=alpha
            ;;
        esac
        version=$(channel_version "${channel}" "${board}")
    else
        channel="${new_channel}"
        version="${new_channel_prev_version}"
    fi
    gcaava_channel_a_ref=${channel}
    gcaava_version_a_ref=${version}
}
# --

function lts_channel_version() (
    local major=${1}; shift
    local board=${1}; shift

    local tmp_lts_info tmp_version_txt
    tmp_lts_info=$(mktemp)
    tmp_version_txt=$(mktemp)
    # This function runs in a subshell, so we can have our own scoped
    # traps.
    trap 'rm "${tmp_lts_info}" "${tmp_version_txt}"' EXIT
    curl_to_stdout 'https://lts.release.flatcar-linux.net/lts-info' >"${tmp_lts_info}"
    local line tuple lts_major year
    while read -r line; do
        # each line is major:year:(supported|unsupported)
        mapfile -t tuple <<<"${line//:/$'\n'}"
        lts_major="${tuple[0]}"
        if [[ ${lts_major} = "${major}" ]]; then
            year="${tuple[1]}"
            break
        fi
    done <"${tmp_lts_info}"

    curl_to_stdout "https://lts.release.flatcar-linux.net/${board}/current-${year}/version.txt" >"${tmp_version_txt}"
    source "${tmp_version_txt}"
    echo "${FLATCAR_VERSION}"
)
# --

# Gets the latest release for given channel and board. For lts channel
# gets a version of the latest LTS. Runs in a subshell.
function channel_version() (
    local channel=${1}; shift
    local board=${1}; shift

    local tmp_version_txt
    tmp_version_txt=$(mktemp)
    # This function runs in a subshell, so we can have our own scoped
    # traps.
    trap 'rm "${tmp_version_txt}"' EXIT

    curl_to_stdout "https://${channel}.release.flatcar-linux.net/${board}/current/version.txt" >"${tmp_version_txt}"
    source "${tmp_version_txt}"
    echo "${FLATCAR_VERSION}"
)
# --

function curl_to_stdout() {
    local url=${1}; shift

    curl \
        -fsSL \
        --retry-delay 1 \
        --retry 60 \
        --retry-connrefused \
        --retry-max-time 60 \
        --connect-timeout 20 \
        "${url}"
}
# --

# Prints some reports using scripts from the passed path to
# flatcar-build-scripts repo. The environment and parameters for the
# scripts are passed as follows:
#
# print_image_reports <flatcar-build-scripts-directory> <previous version description> \\
#       <env vars for package-diff> --- <parameters for package-diff> -- \\
#       <env vars for size-change-report.sh> --- <parameters for size-change-report.sh> -- \\
#       <env vars for show-changes> --- <parameters for show-changes> -- \\
#       <list of OEM ids> -- <list of base sysexts> -- <list of extra sysexts>
#
# Env vars are passed to the called scripts verbatim. Parameters are
# described below.
#
# Parameters for package-diff:
#
# Passed directly to the script, so there should only be two
# parameters - for version A and version B.
#
# Parameters for size-change-report.sh:
#
# Passed directly to the script after appending a ':<kind>' to them,
# so there should be only two parameters being specs without the final
# "kind" part.
#
# Parameters for show-changes:
#
# Should come in format of key=value, just like env vars. It's
# expected that the following key-value pairs will be specified - for
# NEW_CHANNEL, NEW_CHANNEL_PREV_VERSION, NEW_VERSION, OLD_CHANNEL and
# OLD_VERSION.
function print_image_reports() {
    local flatcar_build_scripts_repo=${1}; shift
    local previous_version_description=${1}; shift
    local -a package_diff_env=() package_diff_params=()
    local -a size_change_report_env=() size_change_report_params=()
    local -a show_changes_env=() show_changes_params=()
    local -a oemids base_sysexts extra_sysexts
    local params_shift=0

    split_to_env_and_params \
        package_diff_env package_diff_params params_shift \
        "${@}"
    shift "${params_shift}"
    split_to_env_and_params \
        size_change_report_env size_change_report_params params_shift \
        "${@}"
    shift "${params_shift}"
    split_to_env_and_params \
        show_changes_env show_changes_params params_shift \
        "${@}"
    shift "${params_shift}"
    get_batch_of_args oemids params_shift "${@}"
    shift "${params_shift}"
    get_batch_of_args base_sysexts params_shift "${@}"
    shift "${params_shift}"
    get_batch_of_args extra_sysexts params_shift "${@}"
    shift "${params_shift}"

    flatcar_build_scripts_repo=$(realpath "${flatcar_build_scripts_repo}")

    local size_changes_invocation=(
        env
        "${size_change_report_env[@]}"
        "${flatcar_build_scripts_repo}/size-change-report.sh"
    )

    yell "Image differences compared to ${previous_version_description}"
    underline "Package updates, compared to ${previous_version_description}:"
    env \
        "${package_diff_env[@]}" FILE=flatcar_production_image_packages.txt \
        "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}" 2>&1

    underline "Image file changes, compared to ${previous_version_description}:"
    env \
        "${package_diff_env[@]}" FILE=flatcar_production_image_contents.txt FILESONLY=1 CUTKERNEL=1 \
        "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}" 2>&1

    underline "Image file size changes, compared to ${previous_version_description}:"
    if ! "${size_changes_invocation[@]}" "${size_change_report_params[@]/%/:wtd}" 2>&1; then
        "${size_changes_invocation[@]}" "${size_change_report_params[@]/%/:old}" 2>&1
    fi

    underline "Image kernel config changes, compared to ${previous_version_description}:"
    env \
        "${package_diff_env[@]}" FILE=flatcar_production_image_kernel_config.txt \
        "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}" 2>&1

    underline "Image file size change (includes /boot, /usr and the default rootfs partitions), compared to ${previous_version_description}:"
    env \
        "${package_diff_env[@]}" FILE=flatcar_production_image_contents.txt CALCSIZE=1 \
        "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}" 2>&1

    yell "Init ramdisk differences compared to ${previous_version_description}"
    underline "Image init ramdisk file changes, compared to ${previous_version_description}:"
    env \
        "${package_diff_env[@]}" FILE=flatcar_production_image_initrd_contents.txt FILESONLY=1 CUTKERNEL=1 \
        "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}" 2>&1

    underline "Image init ramdisk file size changes, compared to ${previous_version_description}:"
    if ! "${size_changes_invocation[@]}" "${size_change_report_params[@]/%/:initrd-wtd}" 2>&1; then
        "${size_changes_invocation[@]}" "${size_change_report_params[@]/%/:initrd-old}" 2>&1
    fi
    echo
    echo "Take the total size difference with a grain of salt as normally initrd is compressed, so the actual difference will be smaller."
    echo "To see the actual difference in size, see if there was a report for /boot/flatcar/vmlinuz-a."
    echo "Note that vmlinuz-a also contains the kernel code, which might have changed too, so the reported difference does not accurately describe the change in initrd."
    echo

    local base_sysext
    for base_sysext in "${base_sysexts[@]}"; do
        yell "Base sysext ${base_sysext} changes compared to ${previous_version_description}"
        underline "Package updates, compared to ${previous_version_description}:"
        env \
            "${package_diff_env[@]}" FILE="rootfs-included-sysexts/${base_sysext}_packages.txt" \
            "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}" 2>&1

        underline "Image file changes, compared to ${previous_version_description}:"
        env \
            "${package_diff_env[@]}" FILE="rootfs-included-sysexts/${base_sysext}_contents.txt" FILESONLY=1 CUTKERNEL=1 \
            "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}" 2>&1

        underline "Image file size changes, compared to ${previous_version_description}:"
        if ! "${size_changes_invocation[@]}" "${size_change_report_params[@]/%/:base-sysext-${base_sysext}-wtd}"; then
            "${size_changes_invocation[@]}" "${size_change_report_params[@]/%/:base-sysext-${base_sysext}-old}" 2>&1
        fi
    done

    local extra_sysext
    for extra_sysext in "${extra_sysexts[@]}"; do
        yell "Extra sysext ${extra_sysext} changes compared to ${previous_version_description}"
        underline "Package updates, compared to ${previous_version_description}:"
        env \
            "${package_diff_env[@]}" FILE="flatcar-${extra_sysext}_packages.txt" \
            "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}" 2>&1

        underline "Image file changes, compared to ${previous_version_description}:"
        env \
            "${package_diff_env[@]}" FILE="flatcar-${extra_sysext}_contents.txt" FILESONLY=1 CUTKERNEL=1 \
            "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}" 2>&1

        underline "Image file size changes, compared to ${previous_version_description}:"
        if ! "${size_changes_invocation[@]}" "${size_change_report_params[@]/%/:extra-sysext-${extra_sysext}-wtd}"; then
            "${size_changes_invocation[@]}" "${size_change_report_params[@]/%/:extra-sysext-${extra_sysext}-old}" 2>&1
        fi
    done

    local oemid
    for oemid in "${oemids[@]}"; do
        yell "Sysext changes for OEM ${oemid} compared to ${previous_version_description}"
        underline "Package updates, compared to ${previous_version_description}:"
        env \
            "${package_diff_env[@]}" FILE="oem-${oemid}_packages.txt" \
            "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}" 2>&1

        underline "Image file changes, compared to ${previous_version_description}:"
        env \
            "${package_diff_env[@]}" FILE="oem-${oemid}_contents.txt" FILESONLY=1 CUTKERNEL=1 \
            "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}" 2>&1

        underline "Image file size changes, compared to ${previous_version_description}:"
        if ! "${size_changes_invocation[@]}" "${size_change_report_params[@]/%/:oem-${oemid}-wtd}"; then
            "${size_changes_invocation[@]}" "${size_change_report_params[@]/%/:oem-${oemid}-old}" 2>&1
        fi
    done

    local param
    for param in "${show_changes_params[@]}"; do
        local "SHOW_CHANGES_${param}"
    done
    # The first changelog we print is always against the previous
    # version of the new channel (is only same as old channel and old
    # version without a transition)
    yell "Changelog against ${SHOW_CHANGES_NEW_CHANNEL}-${SHOW_CHANGES_NEW_CHANNEL_PREV_VERSION}"
    env \
        "${show_changes_env[@]}" \
        "${flatcar_build_scripts_repo}/show-changes" \
        "${SHOW_CHANGES_NEW_CHANNEL}-${SHOW_CHANGES_NEW_CHANNEL_PREV_VERSION}" \
        "${SHOW_CHANGES_NEW_VERSION}" 2>&1
    # See if a channel transition happened and print the changelog
    # against old channel and old version which is the previous
    # release
    if [ "${SHOW_CHANGES_OLD_CHANNEL}" != "${SHOW_CHANGES_NEW_CHANNEL}" ]; then
        yell "Changelog against ${SHOW_CHANGES_OLD_CHANNEL}-${SHOW_CHANGES_OLD_VERSION}"
        env \
            "${show_changes_env[@]}" \
            "${flatcar_build_scripts_repo}/show-changes" \
            "${SHOW_CHANGES_OLD_CHANNEL}-${SHOW_CHANGES_OLD_VERSION}" \
            "${SHOW_CHANGES_NEW_VERSION}" 2>&1
    fi
}
# --

function yell() {
    local msg
    msg=${1}; shift

    local msg_len
    msg_len=${#msg}

    local y_str
    repeat_string '!' $((msg_len + 6)) y_str

    printf '\n%s\n!! %s !!\n%s\n\n' "${y_str}" "${msg}" "${y_str}"
}

function underline() {
    local msg
    msg=${1}; shift

    local msg_len
    msg_len=${#msg}

    local u_str
    repeat_string '=' "${msg_len}" u_str

    printf '\n%s\n%s\n\n' "${msg}" "${u_str}"
}

function repeat_string() {
    local str ntimes out_str_var_name
    str="${1}"; shift
    ntimes="${1}"; shift
    out_str_var_name="${1}"; shift
    local -n out_str_ref="${out_str_var_name}"

    if [[ ${ntimes} -eq 0 ]]; then
        out_str_ref=""
        return 0
    elif [[ ${ntimes} -eq 1 ]]; then
        out_str_ref="${str}"
        return 0
    fi
    local add_one
    add_one=$((ntimes % 2))
    repeat_string "${str}${str}" $((ntimes / 2)) "${out_str_var_name}"
    if [[ add_one -gt 0 ]]; then
        out_str_ref+="${str}"
    fi
}

# 1 - name of an array variable for environment variables
# 2 - name of an array variable for parameters
# 3 - name of a scalar variable for shift number
# @ - [ env var key=value pair… [ --- [ parameter… [ -- [ garbage… ] ] ] ] ]
function split_to_env_and_params() {
    local steap_env_var_name=${1}; shift
    local steap_params_var_name=${1}; shift
    local steap_to_shift_var_name=${1}; shift
    local -n steap_env_var_ref="${steap_env_var_name}"
    local -n steap_params_var_ref="${steap_params_var_name}"
    local -n steap_to_shift_var_ref="${steap_to_shift_var_name}"
    local kv param to_shift=0
    local -a env params
    env=()
    params=()
    # rest of parameters are key-value pairs followed by triple dash
    # followed by parameters followed by double dash or nothing
    for kv; do
        if [[ "${kv}" == '--' ]]; then
            break
        fi
        to_shift=$((to_shift + 1))
        if [[ "${kv}" == '---' ]]; then
            break
        fi
        env+=( "${kv}" )
    done
    shift "${to_shift}"
    for param; do
        to_shift=$((to_shift + 1))
        if [[ "${param}" == '--' ]]; then
            break
        fi
        params+=( "${param}" )
    done
    steap_env_var_ref=( "${env[@]}" )
    steap_params_var_ref=( "${params[@]}" )
    steap_to_shift_var_ref=${to_shift}
}
# --

# 1 - name of an array variable that will contain the args
# 2 - name of a scalar variable for shift number
# @ - args with -- as batch separator
function get_batch_of_args() {
    local -n batch_ref=${1}; shift
    local -n shift_ref=${1}; shift

    batch_ref=()
    shift_ref=0
    local arg
    for arg; do
        shift_ref=$((shift_ref + 1))
        if [[ ${arg} = '--' ]]; then
            break
        fi
        batch_ref+=( "${arg}" )
    done
}
# --
