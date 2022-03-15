#!/bin/bash
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the update payload using the previous
# release as starting point, and doing a second update from the current
# build to itself again.
# This script is supposed to run in the SDK container.

work_dir="$1"; shift
arch="$1"; shift
vernum="$1"; shift
tapfile="$1"; shift

# $@ now contains tests / test patterns to run

if [ "$@" != "" ] && [ "$@" != "*" ] && [ "$@" != "cl.update.payload" ]; then
    echo "Only cl.update.payload is supported, got '$@'"
    exit 1
fi

source ci-automation/ci_automation_common.sh
source sdk_lib/sdk_container_common.sh

mkdir -p "${work_dir}"
cd "${work_dir}"

mkdir -p tmp/
if [ -f tmp/flatcar_test_update.gz ] ; then
    echo "++++ QEMU test: Using existing ${work_dir}/tmp/flatcar_test_update.gz for testing ${vernum} (${arch}) ++++"
else
    echo "++++ QEMU test: downloading flatcar_test_update.gz for ${vernum} (${arch}) ++++"
    copy_from_buildcache "images/${arch}/${vernum}/flatcar_test_update.gz" tmp/
fi

ON_CHANNEL="$(get_git_channel)"
if [ "${ON_CHANNEL}" = "developer" ]; then
    # For main/dev builds we compare to last alpha release
    ON_CHANNEL="alpha"
fi
if [ "${ON_CHANNEL}" = "lts" ]; then
    echo "Updating from previous LTS is not supported yet (needs creds), fallback to Stable"
    ON_CHANNEL="stable"
fi
if [ -f tmp/flatcar_production_image_previous.bin ] ; then
    echo "++++ QEMU test: Using existing ${work_dir}/tmp/flatcar_production_image_previous.bin for testing update to ${vernum} (${arch}) from previous ${ON_CHANNEL} ++++"
else
    echo "++++ QEMU test: downloading flatcar_production_image_previous.bin from previous ${ON_CHANNEL} ++++"
    rm -f tmp/flatcar_production_image_previous.bin.bz2
    curl -fsSLO --retry-delay 1 --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 "https://${ON_CHANNEL}.release.flatcar-linux.net/${arch}-usr/current/flatcar_production_image.bin.bz2"
    mv flatcar_production_image.bin.bz2 tmp/flatcar_production_image_previous.bin.bz2
    lbunzip2 -k -f tmp/flatcar_production_image_previous.bin.bz2
fi

bios="${QEMU_BIOS}"
if [ "${arch}" = "arm64" ]; then
    bios="${QEMU_UEFI_BIOS}"
    if [ -f "${bios}" ] ; then
        echo "++++ qemu_update.sh: Using existing ${work_dir}/${bios} ++++"
    else
        echo "++++ qemu_update.sh: downloading ${bios} for ${vernum} (${arch}) ++++"
        copy_from_buildcache "images/${arch}/${vernum}/${bios}" .
    fi
fi

sudo kola run \
    --board="${arch}-usr" \
    --parallel="${QEMU_PARALLEL}" \
    --platform=qemu \
    --qemu-bios="${bios}" \
    --qemu-image=tmp/flatcar_production_image_previous.bin \
    --tapfile="${tapfile}" \
    --torcx-manifest=../torcx_manifest.json \
    --update-payload=tmp/flatcar_test_update.gz \
    cl.update.payload
