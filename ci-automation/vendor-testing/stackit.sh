#!/bin/bash
# Copyright (c) 2025 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for STACKIT vendor.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

stackit_instance_type_var="STACKIT_${CIA_ARCH}_INSTANCE_TYPE"
stackit_instance_type="${!stackit_instance_type_var}"

stackit_location_var="STACKIT_${CIA_ARCH}_LOCATION"
stackit_location="${!stackit_location_var}"

copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/${STACKIT_IMAGE_NAME}" .

kola_test_basename="ci-${CIA_VERNUM//[+.]/-}"

# Upload the image on STACKIT.
IMAGE_ID=$(ore stackit \
  --stackit-service-account-key-path=<(echo "${STACKIT_SERVICE_ACCOUNT}" | base64 --decode) \
  --stackit-project-id="${STACKIT_PROJECT_ID}" \
  create-image \
  --board "${CIA_ARCH}-usr" \
  --name "${kola_test_basename}" \
  --file="${STACKIT_IMAGE_NAME}"
)

set -x

timeout --signal=SIGQUIT 2h kola run \
  --board="${CIA_ARCH}-usr" \
  --parallel="${STACKIT_PARALLEL}" \
  --tapfile="${CIA_TAPFILE}" \
  --channel="${CIA_CHANNEL}" \
  --basename="${kola_test_basename}" \
  --platform=stackit \
  --stackit-service-account-key-path=<(echo "${STACKIT_SERVICE_ACCOUNT}" | base64 --decode) \
  --stackit-project-id="${STACKIT_PROJECT_ID}" \
  --stackit-image-id="${IMAGE_ID}" \
  --stackit-type="${stackit_instance_type}" \
  --stackit-availability-zone="${stackit_location}" \
  --image-version "${CIA_VERNUM}" \
  "${@}"

set +x
