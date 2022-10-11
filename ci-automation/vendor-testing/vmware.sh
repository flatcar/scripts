#!/bin/bash
# Copyright (c) 2022 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the VMware ESX vendor image.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

# We never ran VMware ESX on arm64, so for now fail it as an
# unsupported option.
if [[ "${CIA_ARCH}" == "arm64" ]]; then
    echo "1..1" > "${CIA_TAPFILE}"
    echo "not ok - all qemu tests" >> "${CIA_TAPFILE}"
    echo "  ---" >> "${CIA_TAPFILE}"
    echo "  ERROR: ARM64 tests not supported on VMware ESX." | tee -a "${CIA_TAPFILE}"
    echo "  ..." >> "${CIA_TAPFILE}"
    break_retest_cycle
    exit 1
fi

# Fetch image if not present.
if [ -f "${VMWARE_ESX_IMAGE_NAME}" ] ; then
    echo "++++ ${CIA_TESTSCRIPT}: Using existing ${VMWARE_ESX_IMAGE_NAME} for testing ${CIA_VERNUM} (${CIA_ARCH}) ++++"
else
    echo "++++ ${CIA_TESTSCRIPT}: downloading ${VMWARE_ESX_IMAGE_NAME} for ${CIA_VERNUM} (${CIA_ARCH}) ++++"
    copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/${VMWARE_ESX_IMAGE_NAME}" .
fi

config_file=''
secret_to_file config_file "${VMWARE_ESX_CREDS}"

# If we are using static IPs, then delete every VM that is running
# because we'll use all available spots. This is to avoid entering a
# broken state if there are some left-over VMs from manual usage or a
# forcefully terminated job.
#
# The assumption here is that we can do it without any interference
# with other CI Vms, because we have acquired a resource lock to those
# VMs.
static_ips="$(jq '.["default"]["static_ips"]' "${config_file}")"
if [[ "${static_ips}" -ne 0 ]]; then
    ore esx --esx-config-file "${config_file}" remove-vms || :
fi

kola_test_basename="ci-${CIA_VERNUM//+/-}"

trap 'ore esx --esx-config-file "${config_file}" remove-vms \
    --pattern "${kola_test_basename}*" || :' EXIT

set -x

sudo timeout --signal=SIGQUIT 2h kola run \
    --board="${CIA_ARCH}-usr" \
    --basename="${kola_test_basename}" \
    --channel="${CIA_CHANNEL}" \
    --platform=esx \
    --tapfile="${CIA_TAPFILE}" \
    --parallel="${VMWARE_ESX_PARALLEL}" \
    --torcx-manifest="${CIA_TORCX_MANIFEST}" \
    --esx-config-file "${config_file}" \
    --esx-ova-path "${VMWARE_ESX_IMAGE_NAME}" \
    "${@}"

set +x
