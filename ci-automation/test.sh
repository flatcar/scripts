#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# >>> This file is supposed to be SOURCED from the repository ROOT. <<<
#
# test_run() should be called w/ the positional INPUT parameters below.

# Test scenarios runner stub.
#   This script will run test scenarios for a single image type.
#   Tests will be started inside the mantle container.
#   This script is generic and will use a vendor-specific test runner from
#    "ci-automation/vendor-testing/<image>.sh.
#
# PREREQUISITES:
#
#   1. SDK version and OS image version are recorded in manifests/version.txt
#   2. Scripts repo version tag of OS image version to be built is available and checked out.
#   3. Mantle container docker image reference is stored in manifests/mantle-container.
#   4. Vendor image to run tests for are available on buildcache
#         ( images/[ARCH]/[FLATCAR_VERSION]/ )
#
# INPUT:
#
#   1. Architecture (ARCH) of the TARGET vm images ("arm64", "amd64").
#   2. Image type to be tested. One of:
#      ami, azure, azure_pro, digitalocean, gce, gce_pro, packet, qemu, qemu_uefi, vmware
#
# OPTIONAL INPUT:
#
#   3. List of tests / test patterns. Defaults to "*" (all tests).
#      All positional arguments after the first 2 (see above) are tests / patterns of tests to run.
#
#   MAX_RETRIES. Environment variable. Number of re-runs to overcome transient failures. Defaults to 20.
#   PARALLEL_TESTS. Environment variable. Number of test cases to run in parallel.
#                   Default is image / vendor specific and defined in ci-automation/ci-config.env.
#
# OUTPUT:
#
#   1. 2 merged TAP reports with all test runs / vendors.
#        - a "summary" report which contains error messages only for tests which never succeeded (per vendor).
#        - a "detailed" report which also contains error messages of transient failures which succeeded after re-runs.
#        These reports will be updated after each (re-)run of each vendor, making the test job safe
#          to abort at any point - the previous runs' results won't be lost.
#   2. All intermediate kola tap reports, kola debug output, and merged tap reports (from 1.) published
#        to buildcache at testing/[VERSION]/[ARCH]/[IMAGE]
#   3. "./ci-cleanup.sh" with commands to clean up temporary build resources,
#        to be run after this step finishes / when this step is aborted.
#
#
# LOW-LEVEL / VENDOR SPECIFIC scripts API
#
# Vendor scripts are provided with their own sub-directory and are expected to CD into there before
#  creating any artifacts (see vendor script argument 1 below).
#
# Vendor specific scripts are called with the following positional arguments:
# 1 - Toplevel tests directory
#     It contains some additional files needed for running the tests (like file with channel information).
# 2 - Working directory for the tests.
#     The vendor script is expected to keep all artifacts it produces in that directory.
# 3 - Architecture to test.
# 4 - Version number to test.
# 5 - Output TAP file.
# All following arguments specify test cases / test case patterns to run.
#
# The vendor tests should source ci-automation/vendor_test.sh script
# as a first step - it will do some common steps that the vendor
# script would need to make anyway. For more information, please refer
# to the vendor_test.sh file.

function __escape_multiple() {
    local out_array_arg_name="${1}"; shift
    # rest are args to be escape and appended into the array named
    # after the first arg
    local -n out_array_arg_ref="${out_array_arg_name}"
    local arg arg_escaped

    out_array_arg_ref=()
    for arg; do
        printf -v arg_escaped '%q' "${arg}"
        out_array_arg_ref+=( "${arg_escaped}" )
    done
}
# --

function test_run() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _test_run_impl "${@}"
    )
}
# --

function _test_run_impl() {
    local arch="$1" ; shift
    local image="$1"; shift

    # default to all tests
    if [ $# -le 0 ] ; then
        set -- '*'
    fi

    local retries="${MAX_RETRIES:-20}"
    local skip_copy_to_bincache=${SKIP_COPY_TO_BINCACHE:-0}

    source ci-automation/tapfile_helper_lib.sh
    source ci-automation/ci_automation_common.sh
    source sdk_lib/sdk_container_common.sh

    source manifests/version.txt
    local vernum="${FLATCAR_VERSION}"
    local docker_vernum
    docker_vernum="$(vernum_to_docker_image_version "${vernum}")"

    local work_dir="${TEST_WORK_DIR}"
    local tests_dir="${work_dir}/${image}"
    mkdir -p "${tests_dir}"

    # Store git version and git channel as files inside ${work_dir}.
    # This information might not be available inside the docker
    # container if this directory is not a main git repo, but rather a
    # git worktree.
    get_git_version >"${work_dir}/git_version"
    get_git_channel >"${work_dir}/git_channel"

    local container_name="flatcar-tests-${arch}-${docker_vernum}-${image}"
    local mantle_ref
    mantle_ref=$(cat manifests/mantle-container)

    local tap_merged_summary="results-${image}"
    local tap_merged_detailed="results-${image}-detailed"
    local retry=""
    local success=false
    local print_give_up=true
    local failed_tests=()
    # A job on each worker prunes old mantle images (docker image prune)
    echo "docker rm -f '${container_name}'" >> ./ci-cleanup.sh

    local image_escaped
    printf -v image_escaped '%q' "${image}"
    local common_test_args=(
        "${work_dir}"
        "${tests_dir}"
        "${arch}"
        "${vernum}"
    )
    local common_test_args_escaped=()
    __escape_multiple common_test_args_escaped "${common_test_args[@]}"

    local tests_escaped=()
    __escape_multiple tests_escaped "${@}"

    # Vendor tests may need to know if it is a first run or a rerun
    touch "${work_dir}/first_run"
    for retry in $(seq "${retries}"); do
        local tapfile="results-run-${retry}.tap"
        local failfile="failed-run-${retry}.txt"
        local tapfile_escaped
        printf -v tapfile_escaped '%q' "${tapfile}"

        # Ignore retcode since tests are flaky. We'll re-run failed tests and
        #  determine success based on test results (tapfile).
        set +e
        touch sdk_container/.env
        docker run --rm --name="${container_name}" --privileged --net host -v /dev:/dev \
          -w /work -v "$PWD":/work "${mantle_ref}" \
         bash -c "git config --global --add safe.directory /work && \
                  source sdk_container/.env && \
                  ci-automation/vendor-testing/${image_escaped}.sh ${common_test_args_escaped[*]} ${tapfile_escaped} ${tests_escaped[*]}"
        set -e
        rm -f "${work_dir}/first_run"

        # Note: git safe.directory is not set in this run as it does not use git
        docker run --rm --name="${container_name}" --privileged --net host -v /dev:/dev \
          -w /work -v "$PWD":/work "${mantle_ref}" \
            ci-automation/test_update_reruns.sh \
                "${arch}" "${vernum}" "${image}" "${retry}" \
                "${tests_dir}/${tapfile}" \
                "${tests_dir}/${failfile}" \
                "${tap_merged_summary}" \
                "${tap_merged_detailed}"

        readarray -t failed_tests <"${tests_dir}/${failfile}"
        if [ "${#failed_tests[@]}" -eq 0 ] ; then
            echo "########### All tests succeeded. ###########"
            success=true
            print_give_up=false
            break
        fi

        if retest_cycle_broken; then
            echo "########### Test cycle requested to break ###########"
            echo "Failed tests:"
            printf '%s\n' "${failed_tests[@]}"
            echo "-----------"
            print_give_up=false
            break
        fi

        echo "########### Some tests failed and will be re-run (${retry} / ${retries}). ###########"
        echo "Failed tests:"
        printf '%s\n' "${failed_tests[@]}"
        echo "-----------"
        __escape_multiple tests_escaped "${failed_tests[@]}"
    done

    if ${print_give_up}; then
        echo "########### All re-runs exhausted ($retries). Giving up. ###########"
    fi

    if [ ${skip_copy_to_bincache} -eq 0 ];then
        # publish kola output, TAP files to build cache
        copy_to_buildcache "testing/${vernum}/${arch}/${image}" \
            "${tests_dir}/_kola_temp"
        copy_to_buildcache "testing/${vernum}/${arch}/${image}" \
            "${tests_dir}/"*.tap
        copy_to_buildcache "testing/${vernum}/${arch}/${image}" \
            "${tap_merged_summary}"*
        copy_to_buildcache "testing/${vernum}/${arch}/${image}" \
            "${tap_merged_detailed}"*
    fi
    if ! $success; then
        return 1
    fi
}
# --
