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

if [ -f "${QEMU_IMAGE_NAME}" ] ; then
    echo "++++ QEMU test: Using existing ${work_dir}/${QEMU_IMAGE_NAME} for testing ${vernum} (${arch}) ++++"
else
    echo "++++ QEMU test: downloading ${QEMU_IMAGE_NAME} for ${vernum} (${arch}) ++++"
    copy_from_buildcache "images/${arch}/${vernum}/${QEMU_IMAGE_NAME}" .
fi

set -o noglob

sudo kola run \
    --board="${arch}-usr" \
    --parallel="${QEMU_PARALLEL}" \
    --platform=qemu \
    --qemu-bios=/usr/share/qemu/bios-256k.bin \
    --qemu-image="${QEMU_IMAGE_NAME}" \
    --tapfile="${tapfile}" \
    --torcx-manifest=../torcx_manifest.json \
    $@

set +o noglob
