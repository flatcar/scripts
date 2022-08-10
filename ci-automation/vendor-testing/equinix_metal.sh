#!/bin/bash
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the Equinix Metal vendor image.
# This script is supposed to run in the mantle container.
# This script requires the PXE images to be built.

source ci-automation/vendor_test.sh

# Equinix Metal ARM server are not yet hourly available in the default `SV` metro
equinixmetal_metro_var="EQUINIXMETAL_${CIA_ARCH}_METRO"
equinixmetal_metro="${!equinixmetal_metro_var}"

EQUINIXMETAL_INSTANCE_TYPE_VAR="EQUINIXMETAL_${CIA_ARCH}_INSTANCE_TYPE"
EQUINIXMETAL_INSTANCE_TYPE="${!EQUINIXMETAL_INSTANCE_TYPE_VAR}"
MORE_INSTANCE_TYPES_VAR="EQUINIXMETAL_${CIA_ARCH}_MORE_INSTANCE_TYPES"
MORE_INSTANCE_TYPES=( ${!MORE_INSTANCE_TYPES_VAR} )

# The maximum is 6h coming from the ore GC duration parameter
timeout=6h

BASE_URL="http://${BUILDCACHE_SERVER}/images/${CIA_ARCH}/${CIA_VERNUM}"

run_kola_tests() {
    local instance_type="${1}"; shift
    local instance_tapfile="${1}"; shift
    local timeout_args=()

    if [[ "${instance_type}" =~ \.xlarge\. ]]; then
        # let's double timeouts for xlarge instances
        timeout_args+=(
            --equinixmetal-launch-timeout=20m
            --equinixmetal-install-timeout=1h30m
        )
    fi

    timeout --signal=SIGQUIT "${timeout}" \
        kola run \
          --board="${CIA_ARCH}-usr" \
          --basename="ci-${CIA_VERNUM/+/-}-${CIA_ARCH}" \
          --platform=equinixmetal \
          --tapfile="${instance_tapfile}" \
          --parallel="${EQUINIXMETAL_PARALLEL}" \
          --torcx-manifest="${CIA_TORCX_MANIFEST}" \
          --equinixmetal-image-url="${BASE_URL}/${EQUINIXMETAL_IMAGE_NAME}" \
          --equinixmetal-installer-image-kernel-url="${BASE_URL}/${PXE_KERNEL_NAME}" \
          --equinixmetal-installer-image-cpio-url="${BASE_URL}/${PXE_IMAGE_NAME}" \
          --equinixmetal-metro="${equinixmetal_metro}" \
          --equinixmetal-plan="${instance_type}" \
          --equinixmetal-project="${EQUINIXMETAL_PROJECT}" \
          --equinixmetal-storage-url="${EQUINIXMETAL_STORAGE_URL}" \
          --gce-json-key=<(set +x; echo "${GCP_JSON_KEY}" | base64 --decode) \
          --equinixmetal-api-key="${EQUINIXMETAL_KEY}" \
          "${timeout_args[@]}" \
          "${@}"
}

query_kola_tests() {
    shift; # ignore the instance type
    kola list --platform=equinixmetal --filter "${@}"
}

run_kola_tests_on_instances \
    "${EQUINIXMETAL_INSTANCE_TYPE}" \
    "${CIA_TAPFILE}" \
    "${CIA_FIRST_RUN}" \
    "${MORE_INSTANCE_TYPES[@]}" \
    '--' \
    'cl.internet' \
    '--' \
    "${@}"
