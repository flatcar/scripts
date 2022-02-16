#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Test execution script for the qemu vendor image.
# This script is supposed to run in the SDK container.

function run_testsuite() {
    local work_dir="$1"; shift
    local arch="$2"; shift
    local vernum="$3"; shift
    local tapfile="$4"; shift

    # $@ now contains tests / test patterns to run

    source ci-automation/ci_automation_common.sh

    mkdir -p "${work_dir}"
    cd "${work_dir}"

    copy_from_buildcache "images/${arch}/${vernum}/${QEMU_IMAGE_NAME}" .

    set -o noglob

    sudo kola run
        --board="${arch}-usr" \
        --parallel="${QEMU_PARALLEL}" \
        --platform=qemu \
        --qemu-bios=/usr/share/qemu/bios-256k.bin \
        --qemu-image="${QEMU_IMAGE_NAME}" \
        --tapfile="${tapfile}" \
        --torcx-manifest="${CONTAINER_TORCX_ROOT}/${arch}-usr/latest/torcx_manifest.json"
        $@

    set +o noglob
}
