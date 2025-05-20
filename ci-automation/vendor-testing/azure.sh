#!/bin/bash
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the azure vendor image.
# This script is supposed to run in the mantle container.

source ci-automation/new_vendor_test.sh

cvt_basename="ci-${CIA_VERNUM//+/-}-${CIA_ARCH}"
cvt_azure_instance_type_var="AZURE_${CIA_ARCH}_MACHINE_SIZE"
cvt_azure_instance_type="${!cvt_azure_instance_type_var}"
cvt_azure_extra_options=()
cvt_other_instance_types=()

if [[ -n "${AZURE_USE_PRIVATE_IPS:-}" ]]; then
    cvt_azure_extra_options+=( --azure-use-private-ips )
fi
if [[ "${CIA_ARCH}" == "arm64" ]] || [[ -n "${AZURE_USE_GALLERY:-}" ]]; then
    cvt_azure_extra_options+=( '--azure-use-gallery' )
fi
if [[ -n "${AZURE_VNET_SUBNET_NAME:-}" ]]; then
    cvt_azure_extra_options+=( --azure-vnet-subnet-name="${AZURE_VNET_SUBNET_NAME}" )
fi
if [[ "${CIA_ARCH}" = 'amd64' ]]; then
    cvt_other_instance_types+=('V1')
fi

CNV_MAIN_INSTANCE="${cvt_azure_instance_type}"
CNV_EXTRA_INSTANCES=( "${cvt_other_instance_types[@]}" )
CNV_EXTRA_INSTANCE_TESTS=( 'cl.internet' )
CNV_PLATFORM=azure
# Align timeout with ore azure gc --duration parameter
CNV_TIMEOUT=6h

failible_setup() {
    cvt_azure_profile_config_file=''
    secret_to_file cvt_azure_profile_config_file "${AZURE_PROFILE}"
    cvt_azure_auth_config_file=''
    secret_to_file cvt_azure_auth_config_file "${AZURE_AUTH_CREDENTIALS}"

    # Fetch the Azure image if not present
    if [ -f "${AZURE_IMAGE_NAME}" ] ; then
        echo "++++ ${CIA_TESTSCRIPT}: Using existing ${AZURE_IMAGE_NAME} for testing ${CIA_VERNUM} (${CIA_ARCH}) ++++"
    else
        echo "++++ ${CIA_TESTSCRIPT}: downloading ${AZURE_IMAGE_NAME} for ${CIA_VERNUM} (${CIA_ARCH}) ++++"
        copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/${AZURE_IMAGE_NAME}.bz2" .
        cp --sparse=always <(lbzcat "${AZURE_IMAGE_NAME}.bz2") "${AZURE_IMAGE_NAME}"
        rm "${AZURE_IMAGE_NAME}.bz2"
    fi
}

get_kola_args() {
    local instance_type="${1}"; shift
    local hyperv_gen="V2"
    if [ "${instance_type}" = "V1" ]; then
        hyperv_gen="V1"
        instance_type="${cvt_azure_instance_type}"
    fi

    local args=(
        --basename="${cvt_basename}"
        --parallel="${AZURE_PARALLEL}"
        --offering=basic
        --azure-image-file="${AZURE_IMAGE_NAME}"
        --azure-location="${AZURE_LOCATION}"
        --azure-profile="${cvt_azure_profile_config_file}"
        --azure-auth="${cvt_azure_auth_config_file}"
        --azure-size="${instance_type}"
        --azure-hyper-v-generation="${hyperv_gen}"
        "${cvt_azure_extra_options[@]}"
    )
    printf '%s\n' "${args}"
}

run_default_kola_tests
