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
# Use the override if explicitly set (even if empty), otherwise default to location-based name.
if [[ -v AZURE_VNET_SUBNET_NAME ]]; then
    azure_vnet_subnet_name="${AZURE_VNET_SUBNET_NAME}"
else
    azure_vnet_subnet_name="jenkins-vnet-${AZURE_LOCATION}"
fi

# Fetch the Azure image if not present
if [[ -n "${AZURE_DISK_URI:-}" ]]; then
    echo "++++ ${CIA_TESTSCRIPT}: Using gallery image via --azure-disk-uri (skipping VHD download) ++++"
elif [ -f "${AZURE_IMAGE_NAME}" ] ; then
    echo "++++ ${CIA_TESTSCRIPT}: Using existing ${AZURE_IMAGE_NAME} for testing ${CIA_VERNUM} (${CIA_ARCH}) ++++"
else
    echo "++++ ${CIA_TESTSCRIPT}: downloading ${AZURE_IMAGE_NAME} for ${CIA_VERNUM} (${CIA_ARCH}) ++++"
    copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/${AZURE_IMAGE_NAME}.bz2" .
    cp --sparse=always <(lbzcat "${AZURE_IMAGE_NAME}.bz2") "${AZURE_IMAGE_NAME}"
    rm "${AZURE_IMAGE_NAME}.bz2"
fi

run_kola_tests() {
    local instance_type="${1}"; shift
    local instance_tapfile="${1}"; shift
    local hyperv_gen sku

    if [ "${instance_type}" = "V1" ]; then
        hyperv_gen="V1"
        sku="alpha"
        # v5 is the last to support Gen 1. Only amd64 uses Gen 1.
        instance_type="Standard_D2s_v5"
    else
        hyperv_gen="V2"
        sku="alpha-gen2"
        # --azure-use-gallery is only consumed by mantle when it is creating a
        # new image from a blob/file. On the --azure-disk-uri path mantle
        # consumes the disk URI directly and ignores --azure-use-gallery, so
        # skip the flag to keep the kola invocation honest.
        if [[ -z "${AZURE_DISK_URI:-}" ]]; then
            set -- --azure-use-gallery "${@}"
        fi
    fi

    # Align timeout with ore azure gc --duration parameter
    debug_flag=""
    if [[ "${KOLA_DEBUG:-}" == "true" ]]; then
        debug_flag="--debug"
    fi

    # Determine image reference: gallery image via disk URI or local VHD
    local image_arg
    if [[ -n "${AZURE_DISK_URI:-}" ]]; then
        image_arg="--azure-disk-uri=${AZURE_DISK_URI}"
    else
        image_arg="--azure-image-file=${AZURE_IMAGE_NAME}"
    fi

    timeout --signal=SIGQUIT 6h \
      kola run \
      ${debug_flag} \
      ${distro_flag:-} \
      --board="${board}" \
      --basename="${basename}" \
      --parallel="${AZURE_PARALLEL}" \
      --offering=basic \
      --platform=azure \
      ${image_arg} \
      --azure-location="${AZURE_LOCATION}" \
      --tapfile="${instance_tapfile}" \
      --azure-size="${instance_type}" \
      --azure-sku="${sku}" \
      --azure-hyper-v-generation="${hyperv_gen}" \
      ${AZURE_USE_GALLERY} \
      ${AZURE_KOLA_VNET:+--azure-kola-vnet=${AZURE_KOLA_VNET}} \
      ${azure_vnet_subnet_name:+--azure-vnet-subnet-name=${azure_vnet_subnet_name}} \
      ${AZURE_USE_PRIVATE_IPS:+--azure-use-private-ips=${AZURE_USE_PRIVATE_IPS}} \
      ${AZURE_RESOURCE_GROUP_TAG:+--azure-resource-group-tag=${AZURE_RESOURCE_GROUP_TAG}} \
      ${KOLA_TRUSTED_SOURCE_CIDR:+--trusted-source-cidr=${KOLA_TRUSTED_SOURCE_CIDR}} \
      --image-version "${CIA_VERNUM}" \
      "${@}"
}

query_kola_tests() {
    shift; # ignore the instance type
    kola list --platform=azure --filter "${@}"
}

other_instance_types=()
# RPM/ACL mode: no Gen1 support and no GPU quota, skip extra instance types.
if [[ "${CIA_ARCH}" = 'amd64' ]] && [[ "${PACKAGE_SOURCE_MODE:-PORTAGE}" != 'RPM' ]]; then
    # Gen1 (V1) is incompatible with --azure-disk-uri: a gallery image-definition
    # is locked to a single Hyper-V generation, and our *-test image-defs are
    # Gen2-only. Skip the V1 run when running in disk-URI (gallery) mode.
    if [[ -z "${AZURE_DISK_URI:-}" ]]; then
        other_instance_types+=('V1')
    fi
    other_instance_types+=('Standard_NC6s_v3')
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
