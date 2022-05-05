#!/bin/bash
# Copyright (c) 2022 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the Digital Ocean vendor image.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

# We never ran Digital Ocean on arm64, so for now fail it as an
# unsupported option.
if [[ "${CIA_ARCH}" == "arm64" ]]; then
    echo "1..1" > "${CIA_TAPFILE}"
    echo "not ok - all Digital Ocean tests" >> "${CIA_TAPFILE}"
    echo "  ---" >> "${CIA_TAPFILE}"
    echo "  ERROR: ARM64 tests not supported on Digital Ocean." | tee -a "${CIA_TAPFILE}"
    echo "  ..." >> "${CIA_TAPFILE}"
    break_retest_cycle
    exit 1
fi

image_name="ci-${CIA_VERNUM//+/-}"
image_url="$(url_from_template "${DO_IMAGE_URL}" "${CIA_ARCH}" "${CIA_CHANNEL}" 'https' "${CIA_VERNUM}")"

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
    --channel="${CIA_CHANNEL}" \
    --tapfile="${CIA_TAPFILE}" \
    --torcx-manifest="${CIA_TORCX_MANIFEST}" \
    "${@}"

set +x
