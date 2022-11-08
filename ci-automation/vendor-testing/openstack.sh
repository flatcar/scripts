#!/bin/bash
# Copyright (c) 2022 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the Openstack vendor image.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

# ARM64 does not seem to be supported yet with devstack, so for now fail it as an
# unsupported option.
if [[ "${CIA_ARCH}" == "arm64" ]]; then
    echo "1..1" > "${CIA_TAPFILE}"
    echo "not ok - all Openstack tests" >> "${CIA_TAPFILE}"
    echo "  ---" >> "${CIA_TAPFILE}"
    echo "  ERROR: ARM64 tests not supported on Openstack (devstack)." | tee -a "${CIA_TAPFILE}"
    echo "  ..." >> "${CIA_TAPFILE}"
    break_retest_cycle
    exit 1
fi

# OPENSTACK_CREDS, OPENSTACK_USER, OPENSTACK_HOST, OPENSTACK_KEYFILE should be provided by sdk_container/.env
config_file=''
secret_to_file config_file "${OPENSTACK_CREDS}"

openstack_keyfile=''
secret_to_file openstack_keyfile "${OPENSTACK_KEYFILE}"

# Upload the image on OpenStack dev instance.
IMAGE_ID=$(ore openstack create-image \
  --name=flatcar-"${CIA_VERNUM}" \
  --file="https://${BUILDCACHE_SERVER}/images/${CIA_ARCH}/${CIA_VERNUM}/${OPENSTACK_IMAGE_NAME}" \
  --config-file="${config_file}"
)

# Delete the image once we exit.
trap 'ore --config-file "${config_file}" openstack delete-image --id "${IMAGE_ID}" || true' EXIT

kola_test_basename="ci-${CIA_VERNUM//+/-}"
kola_test_basename="${kola_test_basename//[+.]/-}"

set -x

timeout --signal=SIGQUIT 2h kola run \
  --board="${CIA_ARCH}-usr" \
  --parallel="${OPENSTACK_PARALLEL}" \
  --tapfile="${CIA_TAPFILE}" \
  --channel="${CIA_CHANNEL}" \
  --torcx-manifest="${CIA_TORCX_MANIFEST}" \
  --basename="${kola_test_basename}" \
  --platform=openstack \
  --openstack-network=public \
  --openstack-domain=default \
  --openstack-flavor=flatcar-flavor \
  --openstack-user="${OPENSTACK_USER}" \
  --openstack-host="${OPENSTACK_HOST}" \
  --openstack-keyfile="${openstack_keyfile}" \
  --openstack-image="${IMAGE_ID}" \
  --openstack-config-file="${config_file}" \
  "${@}"

set +x
