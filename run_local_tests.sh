#!/bin/bash
#
# Copyright (c) 2023 The Flatcar Maintainers.
# Licensed under the Apache License, Version 2.0 (the "License"); 
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at                         
#
# http://www.apache.org/licenses/LICENSE-2.0                  
#
# QoL wrapper around ci-automation test.sh for running local tests of qemu_uefi image.
# The devcontainer tests will be skipped since these require a valid commit ref in
#   the upstream scripts repo.
#
# Requirements:
# - Docker (for running the Mantle container).
#
# Prerequisites:
# - Flatcar OS image and qemu uefi code to be tested in
#   __build__/images/images/<arch>-usr/latest/
# 
#   This script is intended to be run after building a qemu_uefi image with the SDK container:
#    ./build_packages
#    ./build_image
#    ./image_to_vm.sh --from=../build/images/<arch>-usr/latest/ --format=qemu_uefi --image_compression_formats none
#   Then, EXIT the SDK container (or run this on a different terminal):
#   ./run_local_tests.sh [amd64|arm64]
#
# Optional prerequisites:
# - Custom Mantle container image / version in sdk_container/.repo/manifests/mantle-container.
#   This comes in handy if you've built a local mantle/kola which you want to test.
#   Just edit the file and put in the whole containerr image name and version.
#
# Output:
# results reports:
# - results-qemu_uefi-detailed.md
# - results-qemu_uefi-detailed.tap
# - results-qemu_uefi.md
# - results-qemu_uefi.tap
# - results-qemu_update-detailed.md
# - results-qemu_update-detailed.tap
# - results-qemu_update.md
# - results-qemu_update.tap
#
#
# - Detailed test run output will reside below __TESTS__/qemu-uefi

function set_vars() {
  local arch="${1}"
  local parallel="${2}"

  # Determine image name prefix based on PACKAGE_SOURCE_MODE
  # RPM mode uses "acl_production", PORTAGE mode uses "flatcar_production"
  PACKAGE_SOURCE_MODE="${PACKAGE_SOURCE_MODE:-PORTAGE}"
  local img_prefix="flatcar_production"
  if [[ "${PACKAGE_SOURCE_MODE}" == "RPM" ]]; then
    img_prefix="acl_production"
  fi

  # Read by the mantle container.
  # The local directory ("pwd") will be mounted to /work/ in the container.
  # RPM/ACL mode uses the OEM qcow2 test image (with docker sysext);
  # PORTAGE mode uses the raw .bin image.
  local img_name="${img_prefix}_image.bin"
  if [[ "${PACKAGE_SOURCE_MODE}" == "RPM" ]]; then
    img_name="${img_prefix}_qemu_uefi_test_image.img"
  fi

  cat > sdk_container/.env <<EOF
export QEMU_IMAGE_NAME=/work/__build__/images/images/${arch@Q}-usr/latest/${img_name@Q}
export QEMU_UEFI_FIRMWARE=/work/__build__/images/images/${arch@Q}-usr/latest/${img_prefix@Q}_qemu_uefi_efi_code.qcow2
export QEMU_UEFI_OVMF_VARS=/work/__build__/images/images/${arch@Q}-usr/latest/${img_prefix@Q}_qemu_uefi_efi_vars.qcow2
export QEMU_UEFI_SECURE_FIRMWARE=/work/__build__/images/images/${arch@Q}-usr/latest/${img_prefix@Q}_qemu_uefi_secure_efi_code.qcow2
export QEMU_UEFI_SECURE_OVMF_VARS=/work/__build__/images/images/${arch@Q}-usr/latest/${img_prefix@Q}_qemu_uefi_secure_efi_vars.qcow2
export QEMU_UPDATE_PAYLOAD=/work/__build__/images/images/${arch@Q}-usr/latest/flatcar_test_update.gz
export PARALLEL_TESTS=${parallel@Q}
export KOLA_DEBUG=${KOLA_DEBUG:-}
EOF

  export MAX_RETRIES=${MAX_RUNS:-1}
  echo "[DEBUG] run_local_tests.sh set_vars(): MAX_RUNS=${MAX_RUNS:-<not set>} → MAX_RETRIES=${MAX_RETRIES}"
  export SKIP_COPY_TO_BINCACHE=1
}
#--

function run_local_tests() (
  local arch="${1:-amd64}"
  if [[ $# -gt 0 ]] ; then shift; fi
  local parallel="${1:-2}"
  if [[ $# -gt 0 ]] ; then shift; fi

  rm -f results.*

  local mantle_container="$(cat "sdk_container/.repo/manifests/mantle-container")"
  local tests=""
  local update_tests=false

  # Generate list of all tests for qemu w/o the devcontainer tests.
  # This will generate globs for top-level test modules, e.g. "cl.update.oem" will become cl.*.
  # Globs are necessary because tests ignore OS min/max version specification if a test was specified with its full name.
  # Using globs will prevent tests to be run which aren't meant for the OS version we're testing.
  # NOTE that update tests get special handling because qemu_update is a separate "platform".
  if [[ $# -eq 0 ]] ; then
    tests="$(docker run "${mantle_container}" \
              kola list --platform qemu --board="${arch}-usr" \
              | awk '!/^(devcontainer|Test)/ {if ($1 != "") print gensub(/^([^.]+).*/,"\\1",1,$1) ".*"}' | uniq)"
    update_tests=true
  else
    tests="${@}"
    if [[ "$tests" = *"qemu_update"* ]] ; then
        update_tests=true
    fi
    if [[ "$tests" = "qemu_update" ]] ; then
        tests=""
    fi
  fi

  source ci-automation/test.sh || exit 1
  set_vars "${arch}" "${parallel}"
  
  echo "================================="
  echo "Using Mantle docker image '${mantle_container}'"

  rm -f results.sqlite

  # Choose firmware: use Secure Boot firmware when SECURE_BOOT_ENABLED=true
  # and the secure OVMF files exist, otherwise use standard UEFI firmware.
  local qemu_platform="qemu_uefi"
  local _prefix="flatcar_production"
  if [[ "${PACKAGE_SOURCE_MODE}" == "RPM" ]]; then
    _prefix="acl_production"
  fi
  local secure_firmware="__build__/images/images/${arch}-usr/latest/${_prefix}_qemu_uefi_secure_efi_code.qcow2"
  if [[ "${SECURE_BOOT_ENABLED:-false}" == "true" && -f "${secure_firmware}" ]]; then
    qemu_platform="qemu_uefi_secure"
  fi

  if [[ -n "${tests}" ]] ; then
    echo "================================="
    echo "Running ${qemu_platform} tests"
    test_run "${arch}" "${qemu_platform}" ${tests}
  fi

  if ${update_tests} ; then
    echo "================================="
    echo "Running qemu_update tests"
    test_run "${arch}" qemu_update
  fi

)
# --


if [[ "$(basename "${0}")" = "run_local_tests.sh" ]] ; then
  set -euo pipefail
  run_local_tests "${@}"
fi
