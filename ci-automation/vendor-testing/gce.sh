#!/bin/bash
# Copyright (c) 2022 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the GCE vendor image.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

# We never run GCE on arm64, so for now fail it as an
# unsupported option.
if [[ "${CIA_ARCH}" == "arm64" ]]; then
    echo "1..1" > "${CIA_TAPFILE}"
    echo "not ok - all GCE tests" >> "${CIA_TAPFILE}"
    echo "  ---" >> "${CIA_TAPFILE}"
    echo "  ERROR: ARM64 tests not supported on GCE." | tee -a "${CIA_TAPFILE}"
    echo "  ..." >> "${CIA_TAPFILE}"
    break_retest_cycle
    exit 1
fi

CIA_OUTPUT_MAIN_INSTANCE='default'
CIA_OUTPUT_ALL_TESTS=( "${@}" )
CIA_OUTPUT_EXTRA_INSTANCES=( 'gvnic' )
CIA_OUTPUT_EXTRA_INSTANCE_TESTS=( 'cl.internet' )

query_kola_tests() {
    shift; # ignore the instance type
    kola list --platform=gce --filter "${@}"
}

GCP_JSON_KEY_PATH=''
secret_to_file GCP_JSON_KEY_PATH "${GCP_JSON_KEY}"

copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/${GCE_IMAGE_NAME}" .
gcloud auth activate-service-account --key-file "${GCP_JSON_KEY_PATH}"
gsutil rm -r "${GCE_GCS_IMAGE_UPLOAD}/${CIA_ARCH}-usr/${CIA_VERNUM}" || true
gsutil cp "${GCE_IMAGE_NAME}" "${GCE_GCS_IMAGE_UPLOAD}/${CIA_ARCH}-usr/${CIA_VERNUM}/${GCE_IMAGE_NAME}"
family="ci"
image_name="${family}-${CIA_VERNUM//[+.]/-}"
ore gcloud delete-images --json-key="${GCP_JSON_KEY_PATH}" "${image_name}" || true
ore gcloud create-image \
    --board="${CIA_ARCH}-usr" \
    --family="${family}" \
    --json-key="${GCP_JSON_KEY_PATH}" \
    --source-root="${GCE_GCS_IMAGE_UPLOAD}" \
    --source-name="${GCE_IMAGE_NAME}" \
    --version="${CIA_VERNUM}"

trap 'ore gcloud delete-images \
    --json-key="${GCP_JSON_KEY_PATH}" \
    "${image_name}" ; gsutil rm -r "${GCE_GCS_IMAGE_UPLOAD}/${CIA_ARCH}-usr/${CIA_VERNUM}" || true' EXIT

run_kola_tests() {
    local instance_type="${1}"; shift
    local instance_tapfile="${1}"; shift
    local extra_arg=()
    if [ "${instance_type}" = "gvnic" ]; then
        extra_arg+=("--gce-gvnic")
    fi
    timeout --signal=SIGQUIT 6h \
    kola run \
        --basename="${image_name}" \
        --gce-image="${image_name}" \
        --gce-json-key="${GCP_JSON_KEY_PATH}" \
        --gce-machinetype="${GCE_MACHINE_TYPE}" \
        "${extra_arg[@]}" \
        --parallel="${GCE_PARALLEL}" \
        --platform=gce \
        --channel="${CIA_CHANNEL}" \
        --tapfile="${instance_tapfile}" \
        --torcx-manifest="${CIA_TORCX_MANIFEST}" \
        "${@}"
}

run_kola_tests_on_instances \
    "default" \
    "${CIA_TAPFILE}" \
    "${CIA_FIRST_RUN}" \
    "gvnic" \
    '--' \
    'cl.internet' \
    '--' \
    "${@}"
