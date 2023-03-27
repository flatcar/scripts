#!/bin/bash
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the update payload using the previous
# release as starting point, and doing a second update from the current
# build to itself again.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

# The last check is not perfect (if both tests are rerun, it will only look at the name of the second test) but hopefully still good enough to prevent wrong usage
if [ "$*" != "" ] && [ "$*" != "*" ] && [[ "$*" != *"cl.update.payload" ]]; then
    echo "1..1" > "${CIA_TAPFILE}"
    echo "not ok - all qemu update tests" >> "${CIA_TAPFILE}"
    echo "  ---" >> "${CIA_TAPFILE}"
    echo "  ERROR: Only cl.update.payload is supported, got '$*'." | tee -a "${CIA_TAPFILE}"
    echo "  ..." >> "${CIA_TAPFILE}"
    break_retest_cycle
    exit 1
fi

mkdir -p tmp/
if [ -f tmp/flatcar_test_update.gz ] ; then
    echo "++++ ${CIA_TESTSCRIPT}: Using existing ./tmp/flatcar_test_update.gz for testing ${CIA_VERNUM} (${CIA_ARCH}) ++++"
else
    echo "++++ ${CIA_TESTSCRIPT}: downloading flatcar_test_update.gz for ${CIA_VERNUM} (${CIA_ARCH}) ++++"
    copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/flatcar_test_update.gz" tmp/
fi

if [ -f tmp/flatcar_production_image_previous.bin ] && [ -f tmp/flatcar_production_image_first_dual.bin ] ; then
    echo "++++ ${CIA_TESTSCRIPT}: Using existing ./tmp/flatcar_production_image_{previous,first_dual}.bin for testing update to ${CIA_VERNUM} (${CIA_ARCH}) from previous ${CIA_CHANNEL} and first dual-arch Stable release ++++"
else
    echo "++++ ${CIA_TESTSCRIPT}: downloading flatcar_production_image_previous.bin from previous ${CIA_CHANNEL} ++++"
    rm -f tmp/flatcar_production_image_previous.bin.bz2
    SUFFIX=''
    if [[ "${CIA_CHANNEL}" = 'lts' ]]; then
        LINE=''
        CURRENT_MAJOR="${CIA_VERNUM%%.*}"
        curl -fsSLO --retry-delay 1 --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 'https://lts.release.flatcar-linux.net/lts-info'
        while read -r LINE; do
            # each line is major:year:(supported|unsupported)
            TUPLE=(${LINE//:/ })
            MAJOR="${TUPLE[0]}"
            if [[ "${CURRENT_MAJOR}" = "${MAJOR}" ]]; then
                SUFFIX="-${TUPLE[1]}"
                break
            fi
        done <lts-info
        rm -f lts-info
    fi
    curl -fsSLO --retry-delay 1 --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 "https://${CIA_CHANNEL}.release.flatcar-linux.net/${CIA_ARCH}-usr/current${SUFFIX}/flatcar_production_image.bin.bz2"
    mv flatcar_production_image.bin.bz2 tmp/flatcar_production_image_previous.bin.bz2
    lbunzip2 -k -f tmp/flatcar_production_image_previous.bin.bz2
    echo "++++ ${CIA_TESTSCRIPT}: downloading flatcar_production_image_first_dual.bin from first dual-arch Stable release ++++"
    # We fix the release version here to emulate an update from a very old instance. We could have went with the first Flatcar release but that lacked arm64 support.
    curl -fsSLO --retry-delay 1 --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 "https://stable.release.flatcar-linux.net/${CIA_ARCH}-usr/3033.2.4/flatcar_production_image.bin.bz2"
    mv flatcar_production_image.bin.bz2 tmp/flatcar_production_image_first_dual.bin.bz2
    lbunzip2 -k -f tmp/flatcar_production_image_first_dual.bin.bz2
fi

bios="${QEMU_BIOS}"
if [ "${CIA_ARCH}" = "arm64" ]; then
    bios="${QEMU_UEFI_BIOS}"
    if [ -f "${bios}" ] ; then
        echo "++++ qemu_update.sh: Using existing ./${bios} ++++"
    else
        echo "++++ qemu_update.sh: downloading ${bios} for ${CIA_VERNUM} (${CIA_ARCH}) ++++"
        copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/${bios}" .
    fi
fi

query_kola_tests() {
    shift; # ignore the instance type
    local arg
    arg="${*}"
    if [ "${arg}" != "" ]; then
      # Empty calls are ok, which mean no tests, but otherwise we restrict the tests to run
      arg="cl.update.payload"
    fi
    kola list --platform=qemu --filter "${arg}"
}

run_kola_tests() {
    local instance_type="${1}"; shift;
    local instance_tapfile="${1}"; shift
    local image
    if [ "${instance_type}" = "previous" ]; then
        image="tmp/flatcar_production_image_previous.bin"
    elif [ "${instance_type}" = "first_dual" ]; then
        image="tmp/flatcar_production_image_first_dual.bin"
    else
        echo "Wrong instance type ${instance_type}" >&2
        exit 1
    fi

    kola run \
      --board="${CIA_ARCH}-usr" \
      --parallel="${QEMU_PARALLEL}" \
      --platform=qemu \
      --qemu-bios="${bios}" \
      --qemu-image="${image}" \
      --tapfile="${instance_tapfile}" \
      --torcx-manifest="${CIA_TORCX_MANIFEST}" \
      --update-payload=tmp/flatcar_test_update.gz \
      ${QEMU_KOLA_SKIP_MANGLE:+--qemu-skip-mangle} \
      cl.update.payload
}

run_kola_tests_on_instances "previous" "${CIA_TAPFILE}" "${CIA_FIRST_RUN}" first_dual -- cl.update.payload -- "${@}"
