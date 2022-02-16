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
#   Tests will be started inside a container based on the packages container image
#    (which contains the torcx manifest).
#   This script is generic and will use a vendor-specific test runner from
#    "ci-automation/vendor-testing/<image>.sh.
#
# PREREQUISITES:
#
#   1. SDK version and OS image version are recorded in sdk_container/.repo/manifests/version.txt
#   2. Scripts repo version tag of OS image version to be built is available and checked out.
#   3. Flatcar packages container is available via build cache server
#       from "/containers/[VERSION]/flatcar-packages-[ARCH]-[FLATCAR_VERSION].tar.gz"
#       or present locally. Container must contain binary packages and torcx artefacts.
#   4. Vendor image(s) to run tests for are available on buildcache ( images/[ARCH]/[FLATCAR_VERSION]/ )
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
#   MAX_RETRIES. Environment variable. Number of re-runs to overcome transient failures. Defaults to 999.
#
# OUTPUT:
#
#   1. 2 merged TAP reports with all test runs / vendors.
#        - a "summary" report which contains error messages only for tests which never succeeded (per vendor).
#        - a "detailed" report which also contains error messages of transient failures which succeeded after re-runs.
#        These reports will be updated after each (re-)run of each vendor, making the test job safe
#          to abort at any point - the previous runs' results won't be lost.
#   2. "./ci-cleanup.sh" with commands to clean up temporary build resources,
#        to be run after this step finishes / when this step is aborted.

set -eu

function test_run() {
    local arch="$1" ; shift
    local image="$2"; shift

    # default to all tests
    if [ $# -le 0 ] ; then
        set -- *
    fi

    source ci-automation/tapfile_helper_lib.sh
    source ci-automation/ci_automation_common.sh
    init_submodules

    source sdk_container/.repo/manifests/version.txt
    local vernum="${FLATCAR_VERSION}"
    local docker_vernum="$(vernum_to_docker_image_version "${vernum}")"

    local packages="flatcar-packages-${arch}"
    local packages_image="${packages}:${docker_vernum}"

    docker_image_from_buildcache "${packages}" "${docker_vernum}"

    local tests_dir="__TESTS__/${image}"
    mkdir -p "${tests_dir}"

    local container_name="flatcar-tests-${arch}-${docker_vernum}-${image}"

    local retry=""
    local success=false
    for retry in $(seq "${retries}"); do
        local tapfile="results-run-${retry}.tap"
        local failfile="failed-run-${retry}."

        set -o noglob
        ./run_sdk_container -n "${container_name}" -C "${packages_image}" -v "${vernum}" \
            ci-automation/vendor/testing/"${image}".sh \
                "${tests_dir}" \
                "${arch}" \
                "${vernum}" \
                "${tapfile}" \
                $@
        set +o noglob

        ./run_sdk_container -n "${container_name}" -C "${packages_image}" -v "${vernum}" \
            ci-automation/test_update_reruns.sh \
                "${tests_dir}/${tapfile}" "${image}" "${retry}" \
                "${tests_dir}/failed-run-${retry}.txt"

        local failed_tests="$(cat "${tests_dir}/failed-run-${retry}.txt")"
        if [ -z "$failed_tests" ] ; then
            echo "########### All tests succeeded. ###########"
            success=true
            break
        fi

        echo "########### Some tests failed and will be re-run. ###########"
        echo "Failed tests: $failed_tests"
        echo "-----------"
        set -- $failed_tests
    done

    if ! $success; then
        echo "########### All re-runs exhausted ($retries). Giving up. ###########"
    fi

    # TODO: publish to bincache?
    # "${tests_dir}/"*.tap
    # "${tests_dir}/_kola_temp.tar.xz"

}
# --
