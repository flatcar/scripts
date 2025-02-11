#!/bin/bash
# Copyright (c) 2023 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the Hetzner vendor.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

hetzner_instance_type_var="HETZNER_${CIA_ARCH}_INSTANCE_TYPE"
hetzner_instance_type="${!hetzner_instance_type_var}"

hetzner_location_var="HETZNER_${CIA_ARCH}_LOCATION"
hetzner_location="${!hetzner_location_var}"

# HETZNER_TPS_TOKEN should be provided by sdk_container/.env

# We first need to create a temporary project using HETZNER_TPS_TOKEN
# When the project is created it returns a regular HETZNER_TOKEN that can be used
# in the next commands, it is a token similar to what you would get in your Hetzner console.
HETZNER_TOKEN=$(curl \
    --fail-with-body \
    --retry 2 \
    --silent \
    --user-agent "flatcar-ci/unknown" \
    --request POST \
    --header "Authorization: Bearer ${HETZNER_TPS_TOKEN}" \
    https://tps.hc-integrations.de
)

# Upload the image on Hetzner.
IMAGE_ID=$(ore hetzner \
  --hetzner-token="${HETZNER_TOKEN}" \
  --hetzner-location="${hetzner_location}" \
  create-image \
  --board="${CIA_ARCH}-usr" \
  --name flatcar-"${CIA_VERNUM}" \
  --file="https://${BUILDCACHE_SERVER}/images/${CIA_ARCH}/${CIA_VERNUM}/${HETZNER_IMAGE_NAME}"
)

kola_test_basename="ci-${CIA_VERNUM//[+.]/-}"

set -x

timeout --signal=SIGQUIT 2h kola run \
  --board="${CIA_ARCH}-usr" \
  --parallel="${HETZNER_PARALLEL}" \
  --tapfile="${CIA_TAPFILE}" \
  --channel="${CIA_CHANNEL}" \
  --basename="${kola_test_basename}" \
  --platform=hetzner \
  --hetzner-token="${HETZNER_TOKEN}" \
  --hetzner-server-type="${hetzner_instance_type}" \
  --hetzner-location="${hetzner_location}" \
  --hetzner-image=${IMAGE_ID} \
  "${@}"

set +x
