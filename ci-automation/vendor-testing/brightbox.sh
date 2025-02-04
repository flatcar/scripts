#!/bin/bash
# Copyright (c) 2023 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the Brightbox vendor.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

# ARM64 is not supported on Brightbox, so for now fail it as an
# unsupported option.
if [[ "${CIA_ARCH}" == "arm64" ]]; then
    echo "1..1" > "${CIA_TAPFILE}"
    echo "not ok - all qemu tests" >> "${CIA_TAPFILE}"
    echo "  ---" >> "${CIA_TAPFILE}"
    echo "  ERROR: ARM64 tests not supported on Brightbox." | tee -a "${CIA_TAPFILE}"
    echo "  ..." >> "${CIA_TAPFILE}"
    break_retest_cycle
    exit 1
fi

# BRIGHTBOX_CLIENT_ID, BRIGHTBOX_CLIENT_SECRET should be provided by sdk_container/.env

# Upload the image on Brightbox.
IMAGE_ID=$(ore brightbox create-image \
  --name=flatcar-"${CIA_VERNUM}" \
  --url="https://${BUILDCACHE_SERVER}/images/${CIA_ARCH}/${CIA_VERNUM}/${BRIGHTBOX_IMAGE_NAME}" \
  --brightbox-client-id="${BRIGHTBOX_CLIENT_ID}" \
  --brightbox-client-secret="${BRIGHTBOX_CLIENT_SECRET}"
)

# Remove any left-over servers.
ore brightbox remove-servers \
  --brightbox-client-id="${BRIGHTBOX_CLIENT_ID}" \
  --brightbox-client-secret="${BRIGHTBOX_CLIENT_SECRET}" || :

# Remove any left-over IPs.
ore brightbox remove-ips \
  --brightbox-client-id="${BRIGHTBOX_CLIENT_ID}" \
  --brightbox-client-secret="${BRIGHTBOX_CLIENT_SECRET}" || :

# Delete the image once we exit.
trap 'ore brightbox delete-image --brightbox-client-id="${BRIGHTBOX_CLIENT_ID}" --brightbox-client-secret="${BRIGHTBOX_CLIENT_SECRET}" --id "${IMAGE_ID}" || true' EXIT

kola_test_basename="ci-${CIA_VERNUM//+/-}"
kola_test_basename="${kola_test_basename//[+.]/-}"

set -x

timeout --signal=SIGQUIT 2h kola run \
  --board="${CIA_ARCH}-usr" \
  --parallel="${BRIGHTBOX_PARALLEL}" \
  --tapfile="${CIA_TAPFILE}" \
  --channel="${CIA_CHANNEL}" \
  --basename="${kola_test_basename}" \
  --platform=brightbox \
  --brightbox-image="${IMAGE_ID}" \
  --brightbox-client-id="${BRIGHTBOX_CLIENT_ID}" \
  --brightbox-client-secret="${BRIGHTBOX_CLIENT_SECRET}" \
  --brightbox-server-type="${BRIGHTBOX_SERVER_TYPE}" \
  --image-version "${CIA_VERNUM}" \
  "${@}"

set +x
