#!/bin/bash
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the azure vendor image.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

# $@ now contains tests / test patterns to run

board="${CIA_ARCH}-usr"
basename="ci-${CIA_VERNUM//+/-}-${CIA_ARCH}"
azure_instance_type_var="AZURE_${CIA_ARCH}_MACHINE_SIZE"
azure_instance_type="${!azure_instance_type_var}"
azure_vnet_subnet_name="jenkins-vnet-${AZURE_LOCATION}"

azure_profile_config_file=''
secret_to_file azure_profile_config_file "${AZURE_PROFILE}"
azure_auth_config_file=''
secret_to_file azure_auth_config_file "${AZURE_AUTH_CREDENTIALS}"

# Fetch the Azure image if not present
if [ -f "${AZURE_IMAGE_NAME}" ] ; then
    echo "++++ ${CIA_TESTSCRIPT}: Using existing ${AZURE_IMAGE_NAME} for testing ${CIA_VERNUM} (${CIA_ARCH}) ++++"
else
    echo "++++ ${CIA_TESTSCRIPT}: downloading ${AZURE_IMAGE_NAME} for ${CIA_VERNUM} (${CIA_ARCH}) ++++"
    copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/${AZURE_IMAGE_NAME}.bz2" .
    cp --sparse=always <(lbzcat "${AZURE_IMAGE_NAME}.bz2") "${AZURE_IMAGE_NAME}"
    rm "${AZURE_IMAGE_NAME}.bz2"
fi

if [[ "${CIA_ARCH}" == "arm64" ]]; then
  AZURE_USE_GALLERY="--azure-use-gallery"
fi


run_kola_tests() {
    local instance_type="${1}"; shift
    local instance_tapfile="${1}"; shift
    local hyperv_gen="V2"
    if [ "${instance_type}" = "V1" ]; then
        hyperv_gen="V1"
        instance_type="${azure_instance_type}"
    fi

    # Align timeout with ore azure gc --duration parameter
    timeout --signal=SIGQUIT 6h \
      kola run \
      --board="${board}" \
      --basename="${basename}" \
      --parallel="${AZURE_PARALLEL}" \
      --offering=basic \
      --platform=azure \
      --azure-image-file="${AZURE_IMAGE_NAME}" \
      --azure-location="${AZURE_LOCATION}" \
      --azure-profile="${azure_profile_config_file}" \
      --azure-auth="${azure_auth_config_file}" \
      --torcx-manifest="${CIA_TORCX_MANIFEST}" \
      --tapfile="${instance_tapfile}" \
      --azure-size="${instance_type}" \
      --azure-hyper-v-generation="${hyperv_gen}" \
      ${AZURE_USE_GALLERY} \
      ${azure_vnet_subnet_name:+--azure-vnet-subnet-name=${azure_vnet_subnet_name}} \
      ${AZURE_USE_PRIVATE_IPS:+--azure-use-private-ips=${AZURE_USE_PRIVATE_IPS}} \
      "${@}"
}

query_kola_tests() {
    shift; # ignore the instance type
    kola list --platform=azure --filter "${@}"
}

other_instance_types=("Standard_NC6s_v3")
if [[ "${CIA_ARCH}" = 'amd64' ]]; then
    other_instance_types+=('V1')
fi

run_kola_tests_on_instances \
    "${azure_instance_type}" \
    "${CIA_TAPFILE}" \
    "${CIA_FIRST_RUN}" \
    "${other_instance_types[@]}" \
    '--' \
    'cl.internet' 'cl.misc.nvidia'\
    '--' \
    "${@}"
