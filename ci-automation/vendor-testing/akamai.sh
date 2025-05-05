#!/bin/bash
# Copyright (c) 2023 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for Akamai vendor.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/${AKAMAI_IMAGE_NAME}" .

kola_test_basename="ci-${CIA_VERNUM//[+.]/-}"

# Upload the image on Akamai.
IMAGE_ID=$(ore akamai \
  --akamai-token="${AKAMAI_TOKEN}" \
  --akamai-region="${AKAMAI_REGION}" \
  create-image \
  --name "${kola_test_basename}" \
  --file="${AKAMAI_IMAGE_NAME}"
)

set -x

timeout --signal=SIGQUIT 2h kola run \
  --board="${CIA_ARCH}-usr" \
  --parallel="${AKAMAI_PARALLEL}" \
  --tapfile="${CIA_TAPFILE}" \
  --channel="${CIA_CHANNEL}" \
  --basename="${kola_test_basename}" \
  --platform=akamai \
  --akamai-token="${AKAMAI_TOKEN}" \
  --akamai-type="${AKAMAI_INSTANCE_TYPE}" \
  --akamai-region="${AKAMAI_REGION}" \
  --akamai-image="${IMAGE_ID}" \
  --image-version "${CIA_VERNUM}" \
  "${@}"

set +x
