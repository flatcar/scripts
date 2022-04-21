#!/bin/bash
# Copyright (c) 2022 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the Digital Ocean vendor image.
# This script is supposed to run in the mantle container.

work_dir="$1"; shift
arch="$1"; shift
vernum="$1"; shift
tapfile="$1"; shift

# $@ now contains tests / test patterns to run

source ci-automation/ci_automation_common.sh
source sdk_lib/sdk_container_common.sh

mkdir -p "${work_dir}"
cd "${work_dir}"

# We never ran Digital Ocean on arm64, so for now fail it as an
# unsupported option.
if [[ "${arch}" == "arm64" ]]; then
    echo "1..1" > "${tapfile}"
    echo "not ok - all digital ocean tests" >> "${tapfile}"
    echo "  ---" >> "${tapfile}"
    echo "  ERROR: ARM64 tests not supported on Digital Ocean." | tee -a "${tapfile}"
    echo "  ..." >> "${tapfile}"
    exit 1
fi

channel="$(get_git_channel)"
if [[ "${channel}" = 'developer' ]]; then
    channel='alpha'
fi
image_name="ci-${vernum//+/-}"
testscript="$(basename "$0")"
image_url="${DO_IMAGE_URL//@ARCH@/${arch}}"
image_url="${image_url//@CHANNEL@/${channel}}"
image_url="${image_url//@VERNUM@/${vernum}}"

ore do create-image \
    --config-file="${DO_CONFIG_FILE}" \
    --region="${DO_REGION}" \
    --name="${image_name}" \
    --url="${image_url}"

trap 'ore do delete-image \
    --name="${image_name}" \
    --config-file="${DO_CONFIG_FILE}"' EXIT

set -x

timeout --signal=SIGQUIT 4h\
    kola run \
    --do-size="${DO_MACHINE_SIZE}" \
    --do-region="${DO_REGION}" \
    --basename="${image_name}" \
    --do-config-file="${DO_CONFIG_FILE}" \
    --do-image="${image_name}" \
    --parallel="${DO_PARALLEL}" \
    --platform=do \
    --channel="${channel}" \
    --tapfile="${tapfile}" \
    --torcx-manifest='../torcx_manifest.json' \
    "${@}"

set +x
