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

CIA_OUTPUT_MAIN_INSTANCE='default'
CIA_OUTPUT_ALL_TESTS=( "${@}" )
CIA_OUTPUT_EXTRA_INSTANCES=()
CIA_OUTPUT_EXTRA_INSTANCE_TESTS=()
CIA_OUTPUT_TIMEOUT=2h

query_kola_tests() {
    shift; # ignore the instance type
    kola list --platform=openstack --filter "${@}"
}

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

run_kola_tests() {
    shift # ignore the instance type

    kola_run \
        --parallel="${OPENSTACK_PARALLEL}" \
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
}

run_default_kola_tests
