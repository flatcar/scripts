#!/bin/bash
# Copyright (c) 2022 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the GCE vendor image.
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

# We never run GCE on arm64, so for now fail it as an
# unsupported option.
if [[ "${arch}" == "arm64" ]]; then
    echo "1..1" > "${tapfile}"
    echo "not ok - all GCE tests" >> "${tapfile}"
    echo "  ---" >> "${tapfile}"
    echo "  ERROR: ARM64 tests not supported on GCE." | tee -a "${tapfile}"
    echo "  ..." >> "${tapfile}"
    exit 1
fi

channel="$(get_git_channel)"
if [[ "${channel}" = 'developer' ]]; then
    channel='alpha'
fi
testscript="$(basename "$0")"

# Create temp file and delete it immediately
echo "${GCP_JSON_KEY}" | base64 --decode > /tmp/gcp_auth
exec {gcp_auth}</tmp/gcp_auth
rm /tmp/gcp_auth
GCP_JSON_KEY_PATH="/proc/$$/fd/${gcp_auth}"

copy_from_buildcache "images/${arch}/${vernum}/${GCE_IMAGE_NAME}" .
gcloud auth activate-service-account --key-file "${GCP_JSON_KEY_PATH}"
gsutil rm -r "${GCE_GCS_IMAGE_UPLOAD}/${arch}-usr/${vernum}" || true
gsutil cp "${GCE_IMAGE_NAME}" "${GCE_GCS_IMAGE_UPLOAD}/${arch}-usr/${vernum}/${GCE_IMAGE_NAME}"
family="ci"
image_name="${family}-${vernum//[+.]/-}"
ore gcloud delete-images --json-key="${GCP_JSON_KEY_PATH}" "${image_name}" || true
ore gcloud create-image \
    --board="${arch}-usr" \
    --family="${family}" \
    --json-key="${GCP_JSON_KEY_PATH}" \
    --source-root="${GCE_GCS_IMAGE_UPLOAD}" \
    --source-name="${GCE_IMAGE_NAME}" \
    --version="${vernum}"

trap 'ore gcloud delete-images \
    --json-key="${GCP_JSON_KEY_PATH}" \
    "${image_name}" ; gsutil rm -r "${GCE_GCS_IMAGE_UPLOAD}/${arch}-usr/${vernum}" || true' EXIT

set -x

timeout --signal=SIGQUIT 6h \
    kola run \
    --basename="${image_name}" \
    --gce-image="${image_name}" \
    --gce-json-key="${GCP_JSON_KEY_PATH}" \
    --gce-machinetype="${GCE_MACHINE_TYPE}" \
    --parallel="${GCE_PARALLEL}" \
    --platform=gce \
    --channel="${channel}" \
    --tapfile="${tapfile}" \
    --torcx-manifest='../torcx_manifest.json' \
    "${@}"

set +x
