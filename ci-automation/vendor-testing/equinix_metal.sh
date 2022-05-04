#!/bin/bash
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the Equinix Metal vendor image.
# This script is supposed to run in the SDK container.
# This script requires "pxe" Jenkins job.

work_dir="$1"; shift
arch="$1"; shift
vernum="$1"; shift
tapfile="$1"; shift

# $@ now contains tests / test patterns to run

source ci-automation/ci_automation_common.sh
# required for get_git_channel
source sdk_lib/sdk_container_common.sh

channel="$(get_git_channel)"

mkdir -p "${work_dir}"
cd "${work_dir}"

# Equinix Metal ARM server are not yet hourly available in the default `SV` metro
equinixmetal_metro_var="EQUINIXMETAL_${arch}_METRO"
equinixmetal_metro="${!equinixmetal_metro_var}"

EQUINIXMETAL_INSTANCE_TYPE_VAR="EQUINIXMETAL_${arch}_INSTANCE_TYPE"
EQUINIXMETAL_INSTANCE_TYPE="${!EQUINIXMETAL_INSTANCE_TYPE_VAR}"
MORE_INSTANCE_TYPES_VAR="EQUINIXMETAL_${arch}_MORE_INSTANCE_TYPES"
MORE_INSTANCE_TYPES=( ${!MORE_INSTANCE_TYPES_VAR} )

# The maximum is 6h coming from the ore GC duration parameter
timeout=6h

BASE_URL="http://${BUILDCACHE_SERVER}/images/${arch}/${vernum}"

run_equinix_metal_kola_test() {
    local instance_type="${1}"
    local instance_tapfile="${2}"

    timeout --signal=SIGQUIT "${timeout}" \
        kola run \
          --board="${arch}-usr" \
          --basename="ci-${vernum/+/-}" \
          --platform=equinixmetal \
          --tapfile="${instance_tapfile}" \
          --parallel="${EQUINIXMETAL_PARALLEL}" \
          --torcx-manifest=../torcx_manifest.json \
          --equinixmetal-image-url="${BASE_URL}/${EQUINIXMETAL_IMAGE_NAME}" \
          --equinixmetal-installer-image-kernel-url="${BASE_URL}/${PXE_KERNEL_NAME}" \
          --equinixmetal-installer-image-cpio-url="${BASE_URL}/${PXE_IMAGE_NAME}" \
          --equinixmetal-metro="${equinixmetal_metro}" \
          --equinixmetal-plan="${instance_type}" \
          --equinixmetal-project="${EQUINIXMETAL_PROJECT}" \
          --equinixmetal-storage-url="${EQUINIXMETAL_STORAGE_URL}" \
          --gce-json-key=<(set +x; echo "${GCP_JSON_KEY}" | base64 --decode) \
          --equinixmetal-api-key="${EQUINIXMETAL_KEY}" \
          "${@}"

    # compare the tested instance with the default instance type.
    if [[ "${instance_type}" != "${EQUINIXMETAL_INSTANCE_TYPE}" ]]; then
        sed --in-place "s/cl\.internet/${instance_type}\.cl\.internet/" "${instance_tapfile}"
    fi
}

cl_internet_included="$(kola list --platform=equinixmetal --filter "${@}" | { grep cl.internet || : ; } )"

# in case of rerun, we need to convert <instance-type>.cl.internet
# to regular cl.internet tests on the correct instance type.
instance_types=()
for t in "${@}"; do
    if [[ "${t}" =~ ".cl.internet" ]]; then
        instance_types+=( "${t/\.cl\.internet/}" )
        # cl_internet needs to run.
        cl_internet_included="yes"
    fi
done
# Remove any <instance-type>.cl.internet in ${@}
set -o noglob
set -- $(echo "$*" | sed 's/[^[:space:]]*\.cl\.internet//g')
set +o noglob

# empty array is seen as unbound variable.
set +u
[[ "${#instance_types}" -gt 0 ]] && MORE_INSTANCE_TYPES=( "${instance_types[@]}" )
set -u

run_more_tests=0

[[ -n "${cl_internet_included}" ]] && [[ "${#MORE_INSTANCE_TYPES[@]}" -gt 0 ]] && run_more_tests=1

if [[ "${run_more_tests}" -eq 1 ]]; then
    for instance_type in "${MORE_INSTANCE_TYPES[@]}"; do
	(
            OUTPUT=$(set +x; run_equinix_metal_kola_test "${instance_type}" "validate_${instance_type}.tap" 'cl.internet' 2>&1 || :)
            echo "=== START ${instance_type} ==="
            echo "${OUTPUT}" | sed "s/^/${instance_type}: /g"
            echo "=== END ${instance_type} ==="
        ) &
    done
fi

# Skip regular run if only <instance-type>.cl.internet were to be tested
ARGS="$*"
if [[ -n "${ARGS// }" ]]; then
    set -x
    run_equinix_metal_kola_test "${EQUINIXMETAL_INSTANCE_TYPE}" "${tapfile}" "${@}"
    set +x
fi

if [[ "${run_more_tests}" -eq 1 ]]; then
    wait
    cat validate_*.tap >>"${tapfile}"
fi
