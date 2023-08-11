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

    local arch=${1}
    local channel vernum

    channel=$(source sdk_lib/sdk_container_common.sh; get_git_channel)
    if [ "${channel}" = "developer" ]; then
            channel="alpha"
    fi
    vernum=$(source sdk_container/.repo/manifests/version.txt; echo "${FLATCAR_VERSION}")

    local -a package_diff_env package_diff_params_b
    local -a size_changes_env size_changes_params_b
    local -a show_changes_env show_changes_params_overrides

    package_diff_env=(
        "FROM_B=bincache"
        "BOARD_B=${arch}-usr"
        # CHANNEL_B is unused
    )
    package_diff_params_b=(
        "${vernum}"
    )
    size_changes_env=(
        # Nothing to add.
    )
    size_changes_params_b=(
        "bincache:${arch}:${vernum}"
    )
    show_changes_env=(
        # Provide a python3 command for the CVE DB parsing
        "PATH=${PATH}:${PWD}/ci-automation/python-bin"
    )
    show_changes_params_overrides=(
        # Nothing to override.
    )

    local fbs_repo='../flatcar-build-scripts'
    rm -rf "${fbs_repo}"
    git clone \
        --depth 1 \
        "https://github.com/flatcar/flatcar-build-scripts" \
        "${fbs_repo}"
    # Parent directory of the scripts repo, required by some other
    # script.
    local work_directory='..'
    if [[ -z "${BUILDCACHE_SERVER:-}" ]]; then
        local BUILDCACHE_SERVER=$(source ci-automation/ci-config.env; echo "${BUILDCACHE_SERVER}")
    fi
    echo "Image URL: http://${BUILDCACHE_SERVER}/images/${arch}/${vernum}/flatcar_production_image.bin.bz2"
    echo
    generate_image_changes_report \
        "${arch}" "${channel}" "${vernum}" /dev/stdout "${fbs_repo}" "${work_directory}" \
        "${package_diff_env[@]}" --- "${package_diff_params_b[@]}" -- \
        "${size_changes_env[@]}" --- "${size_changes_params_b[@]}" -- \
        "${show_changes_env[@]}" --- "${show_changes_params_overrides[@]}"
)
# --

# 1 - arch
# 2 - channel (alpha, beta, stable or lts)
# 3 - version (FLATCAR_VERSION)
# 4 - report file (can be relative)
# 5 - flatcar-build-scripts directory (can be relative, will be realpathed)
# 6 - work directory for the report scripts (must be a parent directory of the scripts repo, can be relative)
# @ - package-diff env vars --- package-diff version B param -- size-change-report.sh env vars --- size-change-report.sh spec B param -- show-changes env vars --- show-changes param overrides
#
# Example:
#
# generate_image_changes_report \\
#     amd64 alpha 3456.0.0+my-changes reports/images.txt ../flatcar-build-scripts .. \\
#     FROM_B=bincache BOARD_B=amd64-usr --- 3456.0.0+my-changes -- \\
#     --- bincache:amd64:3456.0.0+my-changes -- \\
#     "PATH=${PATH}:${PWD}/ci-automation/python-bin"
function generate_image_changes_report() (
    set -euo pipefail

    local arch=${1}; shift
    local channel=${1}; shift
    local vernum=${1}; shift
    local report_output=${1}; shift
    local flatcar_build_scripts_repo=${1}; shift
    local work_directory=${1}; shift

    local -a package_diff_env package_diff_params
    local -a size_changes_env size_changes_params
    local -a show_changes_env show_changes_params
    local params_shift=0

    split_to_env_and_params \
        package_diff_env package_diff_params params_shift \
        "${@}"
    shift "${params_shift}"
    split_to_env_and_params \
        size_changes_env size_changes_params params_shift \
        "${@}"
    shift "${params_shift}"
    split_to_env_and_params \
        show_changes_env show_changes_params params_shift \
        "${@}"

    local new_channel new_channel_prev_version channel_a version_a
    local board="${arch}-usr"

    new_channel="${channel}"
    new_channel_prev_version=$(channel_version "${new_channel}" "${board}")
    channel_a=''
    version_a=''
    get_channel_a_and_version_a "${new_channel}" "${new_channel_prev_version}" "${vernum}" "${board}" channel_a version_a
    package_diff_env=(
        # For A.
        "FROM_A=release"
        "BOARD_A=${board}"
        "CHANNEL_A=${channel_a}"
        # For B.
        "${package_diff_env[@]}"
    )
    package_diff_params=(
        # For A.
        "${version_a}"
        # For B.
        "${package_diff_params[@]}"
    )

    # Nothing to prepend to size_changes_env.
    #
    # First parts of the size-changes-report specs, the kind is
    # appended at call sites.
    size_changes_params=(
        # For A.
        "release:${channel_a}:${board}:${version_a}"
        # For B.
        "${size_changes_params[@]}"
    )

    # Nothing to prepend to show_changes_env.
    show_changes_params=(
        # The show-changes script expects a tag name, so using git tag
        # here instead of the vernum variable.
        "NEW_VERSION=$(git tag --points-at HEAD)"
        "NEW_CHANNEL=${new_channel}"
        "NEW_CHANNEL_PREV_VERSION=${new_channel_prev_version}"
        # Potential overrides.
        "${show_changes_params[@]}"
    )

    {
        # Using "|| :" to avoid failing the job.
        print_image_reports \
            "${flatcar_build_scripts_repo}" "${channel_a}" "${version_a}" "${work_directory}" \
            "${package_diff_env[@]}" --- "${package_diff_params[@]}" -- \
            "${size_changes_env[@]}" --- "${size_changes_params[@]}" -- \
            "${show_changes_env[@]}" --- "${show_changes_params[@]}" || :
    } >"${report_output}"
)
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

    major_a=$(echo "${new_channel_prev_version}" | cut -d . -f 1)
    major_b=$(echo "${new_channel_new_version}" | cut -d . -f 1)
    # When the major version for the new channel is different, a transition has happened and we can find the previous release in the old channel
    if [ "${major_a}" != "${major_b}" ]; then
        case "${new_channel}" in
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

# Gets the latest release for given channel and board. For lts channel
# gets a version of the latest LTS.
function channel_version() {
    local channel=${1}; shift
    local board=${1}; shift

    curl \
        -fsSL \
        --retry-delay 1 \
        --retry 60 \
        --retry-connrefused \
        --retry-max-time 60 \
        --connect-timeout 20 \
        "https://${channel}.release.flatcar-linux.net/${board}/current/version.txt" | \
        grep -m 1 'FLATCAR_VERSION=' | cut -d = -f 2-
}
# --

# Prints some reports using scripts from the passed path to
# flatcar-build-scripts repo. The environment and parameters for the
# scripts are passed as follows:
#
# print_image_reports <flatcar-build-scripts-directory> <channel a> <version a> <work dir> \\
#       <env vars for package-diff> --- <parameters for package-diff> -- \\
#       <env vars for size-change-report.sh> --- <parameters for size-change-report.sh> -- \\
#       <env vars for show-changes> --- <parameters for show-changes>
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
# NEW_CHANNEL, NEW_CHANNEL_PREV_VERSION NEW_VERSION.
function print_image_reports() {
    local flatcar_build_scripts_repo=${1}; shift
    local channel_a=${1}; shift
    local version_a=${1}; shift
    local work_directory=${1}; shift
    local -a package_diff_env=() package_diff_params=()
    local -a size_change_report_env=() size_change_report_params=()
    local -a show_changes_env=() show_changes_params=()
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

    flatcar_build_scripts_repo=$(realpath "${flatcar_build_scripts_repo}")

    echo "==================================================================="

    echo "== Image differences compared to ${channel_a} ${version_a} =="
    echo "Package updates, compared to ${channel_a} ${version_a}:"
    env \
        --chdir="${work_directory}" \
        "${package_diff_env[@]}" FILE=flatcar_production_image_packages.txt \
        "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}"
    echo
    echo "Image file changes, compared to ${channel_a} ${version_a}:"
    env \
        --chdir="${work_directory}" \
        "${package_diff_env[@]}" FILE=flatcar_production_image_contents.txt FILESONLY=1 CUTKERNEL=1 \
        "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}"
    echo
    echo "Image kernel config changes, compared to ${channel_a} ${version_a}:"
    env \
        --chdir="${work_directory}" \
        "${package_diff_env[@]}" FILE=flatcar_production_image_kernel_config.txt \
        "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}"
    echo
    echo "Image init ramdisk file changes, compared to ${channel_a} ${version_a}:"
    env \
        --chdir="${work_directory}" \
        "${package_diff_env[@]}" FILE=flatcar_production_image_initrd_contents.txt FILESONLY=1 \
        "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}"
    echo

    local size_changes_invocation=(
        env
        --chdir="${work_directory}"
        "${size_change_report_env[@]}"
        "${flatcar_build_scripts_repo}/size-change-report.sh"
    )
    echo "Image file size changes, compared to ${channel_a} ${version_a}:"
    if ! "${size_changes_invocation[@]}" "${size_change_report_params[@]/%/:wtd}"; then
        "${size_changes_invocation[@]}" "${size_change_report_params[@]/%/:old}"
    fi
    echo
    echo "Image init ramdisk file size changes, compared to ${channel_a} ${version_a}:"
    if ! "${size_changes_invocation[@]}" "${size_change_report_params[@]/%/:initrd-wtd}"; then
        "${size_changes_invocation[@]}" "${size_change_report_params[@]/%/:initrd-old}"
    fi
    echo "Take the total size difference with a grain of salt as normally initrd is compressed, so the actual difference will be smaller."
    echo "To see the actual difference in size, see if there was a report for /boot/flatcar/vmlinuz-a."
    echo "Note that vmlinuz-a also contains the kernel code, which might have changed too, so the reported difference does not accurately describe the change in initrd."
    echo

    echo "Image file size change (includes /boot, /usr and the default rootfs partitions), compared to ${channel_a} ${version_a}:"
    env \
        --chdir="${work_directory}" \
        "${package_diff_env[@]}" FILE=flatcar_production_image_contents.txt CALCSIZE=1 \
        "${flatcar_build_scripts_repo}/package-diff" "${package_diff_params[@]}"
    echo

    local param
    for param in "${show_changes_params[@]}"; do
        local "SHOW_CHANGES_${param}"
    done
    # The first changelog we print is always against the previous version of the new channel (is only same as ${channel_a} ${version_a} without a transition)
    env \
        --chdir "${work_directory}" \
        "${show_changes_env[@]}" \
        "${flatcar_build_scripts_repo}/show-changes" \
        "${SHOW_CHANGES_NEW_CHANNEL}-${SHOW_CHANGES_NEW_CHANNEL_PREV_VERSION}" \
        "${SHOW_CHANGES_NEW_VERSION}"
    # See if a channel transition happened and print the changelog against ${channel_a} ${version_a} which is the previous release
    if [ "${channel_a}" != "${SHOW_CHANGES_NEW_CHANNEL}" ]; then
        env \
            --chdir "${work_directory}" \
            "${show_changes_env[@]}" \
            "${flatcar_build_scripts_repo}/show-changes" \
            "${channel_a}-${version_a}" \
            "${SHOW_CHANGES_NEW_VERSION}"
    fi
}
# --

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
