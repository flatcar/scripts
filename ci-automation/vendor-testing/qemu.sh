#!/bin/bash
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the qemu vendor image.
# This script is supposed to run in the SDK container.

work_dir="$1"; shift
arch="$1"; shift
vernum="$1"; shift
tapfile="$1"; shift

# $@ now contains tests / test patterns to run

source ci-automation/ci_automation_common.sh

mkdir -p "${work_dir}"
cd "${work_dir}"

testscript="$(basename "$0")"

# ARM64 qemu tests only supported on UEFI
if [ "${arch}" = "arm64" ] && [ "${testscript}" != "qemu_uefi.sh" ] ; then
    echo "1..1" > "${tapfile}"
    echo "not ok - all qemu tests" >> "${tapfile}"
    echo "  ---" >> "${tapfile}"
    echo "  ERROR: ARM64 tests only supported on qemu_uefi." | tee -a "${tapfile}"
    echo "  ..." >> "${tapfile}"
    exit 1
fi

# Fetch image and BIOS if not present
if [ -f "${QEMU_IMAGE_NAME}" ] ; then
    echo "++++ ${testscript}: Using existing ${work_dir}/${QEMU_IMAGE_NAME} for testing ${vernum} (${arch}) ++++"
else
    echo "++++ ${testscript}: downloading ${QEMU_IMAGE_NAME} for ${vernum} (${arch}) ++++"
    copy_from_buildcache "images/${arch}/${vernum}/${QEMU_IMAGE_NAME}" .
fi

bios="${QEMU_BIOS}"
if [ "${testscript}" = "qemu_uefi.sh" ] ; then
    bios="${QEMU_UEFI_BIOS}"
    if [ -f "${bios}" ] ; then
        echo "++++ ${testscript}: Using existing ${work_dir}/${bios} ++++"
    else
        echo "++++ ${testscript}: downloading ${bios} for ${vernum} (${arch}) ++++"
        copy_from_buildcache "images/${arch}/${vernum}/${bios}" .
    fi
fi

set -x
set -o noglob

sudo kola run \
    --board="${arch}-usr" \
    --parallel="${QEMU_PARALLEL}" \
    --platform=qemu \
    --qemu-bios=${bios} \
    --qemu-image="${QEMU_IMAGE_NAME}" \
    --tapfile="${tapfile}" \
    --torcx-manifest=../torcx_manifest.json \
    $@

set +o noglob
set +x
