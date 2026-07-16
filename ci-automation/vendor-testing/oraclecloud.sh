#!/bin/bash
# Copyright (c) 2025 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for OracleCloud vendor.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

oraclecloud_instance_type_var="ORACLECLOUD_${CIA_ARCH}_INSTANCE_TYPE"
oraclecloud_instance_type="${!oraclecloud_instance_type_var}"

oraclecloud_location_var="ORACLECLOUD_${CIA_ARCH}_LOCATION"
oraclecloud_location="${!oraclecloud_location_var}"

oraclecloud_private_key_path=''
secret_to_file oraclecloud_private_key_path "${ORACLECLOUD_PRIVATE_KEY}"

copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/${ORACLECLOUD_IMAGE_NAME}" .

kola_test_basename="ci-${CIA_VERNUM//[+.]/-}"

# Upload the image on OracleCloud.
IMAGE_ID=$(ore oraclecloud \
  --oraclecloud-compartment-id="${ORACLECLOUD_COMPARTMENT_ID}" \
  --oraclecloud-tenancy="${ORACLECLOUD_TENANCY}" \
  --oraclecloud-user="${ORACLECLOUD_USER}" \
  --oraclecloud-fingerprint="${ORACLECLOUD_FINGERPRINT}" \
  --oraclecloud-private-key-path=<(echo "${ORACLECLOUD_PRIVATE_KEY}" | base64 --decode) \
  create-image \
  --oraclecloud-bucket="flatcar-ci-jenkins" \
  --board "${CIA_ARCH}-usr" \
  --name "${kola_test_basename}" \
  --file="${ORACLECLOUD_IMAGE_NAME}"
)

set -x

timeout --signal=SIGQUIT 2h kola run \
  --board="${CIA_ARCH}-usr" \
  --parallel="${ORACLECLOUD_PARALLEL}" \
  --tapfile="${CIA_TAPFILE}" \
  --channel="${CIA_CHANNEL}" \
  --basename="${kola_test_basename}" \
  --platform=oraclecloud \
  --oraclecloud-tenancy="${ORACLECLOUD_TENANCY}" \
  --oraclecloud-user="${ORACLECLOUD_USER}" \
  --oraclecloud-fingerprint="${ORACLECLOUD_FINGERPRINT}" \
  --oraclecloud-private-key-path="${oraclecloud_private_key_path}" \
  --oraclecloud-image-id="${IMAGE_ID}" \
  --oraclecloud-shape="${oraclecloud_instance_type}" \
  --oraclecloud-subnet-id="${ORACLECLOUD_SUBNET_ID}" \
  --oraclecloud-availability-domain="${oraclecloud_location}" \
  --oraclecloud-compartment-id="${ORACLECLOUD_COMPARTMENT_ID}" \
  --image-version "${CIA_VERNUM}" \
  "${@}"

set +x
