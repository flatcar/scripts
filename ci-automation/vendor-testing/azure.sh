#!/bin/bash
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the azure vendor image.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

# $@ now contains tests / test patterns to run

basename="ci-${CIA_VERNUM//+/-}-${CIA_ARCH}"
azure_instance_type_var="AZURE_${CIA_ARCH}_MACHINE_SIZE"
azure_instance_type="${!azure_instance_type_var}"
azure_extra_options=()
other_instance_types=()

if [[ -n "${AZURE_USE_PRIVATE_IPS:-}" ]]; then
    azure_extra_options+=( --azure-use-private-ips )
fi
if [[ "${CIA_ARCH}" == "arm64" ]] || [[ -n "${AZURE_USE_GALLERY:-}" ]]; then
    azure_extra_options+=( '--azure-use-gallery' )
fi
if [[ -n "${AZURE_VNET_SUBNET_NAME:-}" ]]; then
    azure_extra_options+=( --azure-vnet-subnet-name="${AZURE_VNET_SUBNET_NAME}" )
fi
if [[ "${CIA_ARCH}" = 'amd64' ]]; then
    other_instance_types+=('V1')
fi

CIA_OUTPUT_MAIN_INSTANCE="${azure_instance_type}"
CIA_OUTPUT_ALL_TESTS=( "${@}" )
CIA_OUTPUT_EXTRA_INSTANCES=( "${other_instance_types[@]}" )
CIA_OUTPUT_EXTRA_INSTANCE_TESTS=( 'cl.internet' )
# Align timeout with ore azure gc --duration parameter
CIA_OUTPUT_TIMEOUT=6h

query_kola_tests() {
    shift; # ignore the instance type
    kola list --platform=azure --filter "${@}"
}

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


run_kola_tests() {
    local instance_type="${1}"; shift
    local hyperv_gen="V2"
    if [ "${instance_type}" = "V1" ]; then
        hyperv_gen="V1"
        instance_type="${azure_instance_type}"
    fi

    kola_run \
        --basename="${basename}" \
        --parallel="${AZURE_PARALLEL}" \
        --offering=basic \
        --platform=azure \
        --azure-image-file="${AZURE_IMAGE_NAME}" \
        --azure-location="${AZURE_LOCATION}" \
        --azure-profile="${azure_profile_config_file}" \
        --azure-auth="${azure_auth_config_file}" \
        --azure-size="${instance_type}" \
        --azure-hyper-v-generation="${hyperv_gen}" \
        "${azure_extra_options[@]}" \
        "${@}"
}

run_default_kola_tests
