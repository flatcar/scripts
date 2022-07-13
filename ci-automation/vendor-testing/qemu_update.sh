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

if [ "$*" != "" ] && [ "$*" != "*" ] && [ "$*" != "cl.update.payload" ]; then
    echo "Only cl.update.payload is supported, got '$*'"
    exit 1
fi

mkdir -p tmp/
if [ -f tmp/flatcar_test_update.gz ] ; then
    echo "++++ ${CIA_TESTSCRIPT}: Using existing ./tmp/flatcar_test_update.gz for testing ${CIA_VERNUM} (${CIA_ARCH}) ++++"
else
    echo "++++ ${CIA_TESTSCRIPT}: downloading flatcar_test_update.gz for ${CIA_VERNUM} (${CIA_ARCH}) ++++"
    copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/flatcar_test_update.gz" tmp/
fi

if [ -f tmp/flatcar_production_image_previous.bin ] ; then
    echo "++++ ${CIA_TESTSCRIPT}: Using existing ./tmp/flatcar_production_image_previous.bin for testing update to ${CIA_VERNUM} (${CIA_ARCH}) from previous ${CIA_CHANNEL} ++++"
else
    echo "++++ ${CIA_TESTSCRIPT}: downloading flatcar_production_image_previous.bin from previous ${CIA_CHANNEL} ++++"
    rm -f tmp/flatcar_production_image_previous.bin.bz2
    curl -fsSLO --retry-delay 1 --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 "https://${CIA_CHANNEL}.release.flatcar-linux.net/${CIA_ARCH}-usr/current/flatcar_production_image.bin.bz2"
    mv flatcar_production_image.bin.bz2 tmp/flatcar_production_image_previous.bin.bz2
    lbunzip2 -k -f tmp/flatcar_production_image_previous.bin.bz2
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

kola run \
    --board="${CIA_ARCH}-usr" \
    --parallel="${QEMU_PARALLEL}" \
    --platform=qemu \
    --qemu-bios="${bios}" \
    --qemu-image=tmp/flatcar_production_image_previous.bin \
    --tapfile="${CIA_TAPFILE}" \
    --torcx-manifest="${CIA_TORCX_MANIFEST}" \
    --update-payload=tmp/flatcar_test_update.gz \
    --qemu-skip-mangle \
    cl.update.payload
