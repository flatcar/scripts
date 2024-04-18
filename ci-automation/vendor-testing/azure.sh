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

# Fetch the Azure image if not present
if [ ! -f "${AZURE_IMAGE_NAME}" ] ; then
    echo "++++ ${CIA_TESTSCRIPT}: downloading ${AZURE_IMAGE_NAME} for ${CIA_VERNUM} (${CIA_ARCH}) ++++"
    copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/${AZURE_IMAGE_NAME}.bz2" .
    copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/version.txt" .
    cp --sparse=always <(lbzcat "${AZURE_IMAGE_NAME}.bz2") "${AZURE_IMAGE_NAME}"
    rm "${AZURE_IMAGE_NAME}.bz2"
    # ore gc will clean this up within 5h
    imgid=$(ore azure create-gallery-image --azure-identity \
      --azure-location "${AZURE_LOCATION}" \
      --file "${AZURE_IMAGE_NAME}" \
      --hyper-v-generation V2 \
      --board="${board}" | sed 's/{/\n{/' | tail -n1 | jq -r .ID)
    rm -f "${AZURE_IMAGE_NAME}"
    touch "${AZURE_IMAGE_NAME}"
    echo "Using gallery image: $imgid"
    echo "$imgid" >"azure.img"
fi

read -r imgid <"azure.img"
echo "++++ ${CIA_TESTSCRIPT}: Using existing $imgid for testing ${CIA_VERNUM} (${CIA_ARCH}) ++++"

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
      --azure-disk-uri="${imgid}" \
      --azure-location="${AZURE_LOCATION}" \
      --tapfile="${instance_tapfile}" \
      --azure-size="${instance_type}" \
      --azure-hyper-v-generation="${hyperv_gen}" \
      ${azure_vnet_subnet_name:+--azure-vnet-subnet-name=${azure_vnet_subnet_name}} \
      ${AZURE_USE_PRIVATE_IPS:+--azure-use-private-ips=${AZURE_USE_PRIVATE_IPS}} \
      ${AZURE_RESOURCE_GROUP:+--azure-resource-group=${AZURE_RESOURCE_GROUP}} \
      ${AZURE_AVSET_ID:+--azure-availability-set=${AZURE_AVSET_ID}} \
      ${AZURE_TRUSTED_LAUNCH:+--azure-trusted-launch=true} \
      --verbose \
      "${@}"
}

query_kola_tests() {
    shift; # ignore the instance type
    kola list --platform=azure --filter "${@}"
}

other_instance_types=()
if [[ "${CIA_ARCH}" = 'amd64' ]]; then
    : #other_instance_types+=('V1' 'Standard_NC6s_v3')
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
