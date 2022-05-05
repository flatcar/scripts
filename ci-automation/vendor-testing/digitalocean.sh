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
image_url="$(url_from_template "${DIGITALOCEAN_IMAGE_URL_TEMPLATE}" "${CIA_ARCH}" "${CIA_CHANNEL}" 'https' "${CIA_VERNUM}")"

config_file=''
secret_to_file config_file "${DIGITALOCEAN_TOKEN_JSON}"

ore do create-image \
    --config-file="${config_file}" \
    --region="${DIGITALOCEAN_REGION}" \
    --name="${image_name}" \
    --url="${image_url}"

trap 'ore do delete-image \
    --name="${image_name}" \
    --config-file="${config_file}"' EXIT

set -x

timeout --signal=SIGQUIT 4h\
    kola run \
    --do-size="${DIGITALOCEAN_MACHINE_SIZE}" \
    --do-region="${DIGITALOCEAN_REGION}" \
    --basename="${image_name}" \
    --do-config-file="${config_file}" \
    --do-image="${image_name}" \
    --parallel="${DIGITALOCEAN_PARALLEL}" \
    --platform=do \
    --channel="${CIA_CHANNEL}" \
    --tapfile="${CIA_TAPFILE}" \
    --torcx-manifest="${CIA_TORCX_MANIFEST}" \
    "${@}"

set +x
