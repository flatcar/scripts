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
#   __build__/images/images/amd64-usr/latest/
# 
#   This script is intended to be run after building a qemu_uefi image with the SDK container:
#    ./build_packages
#    ./build_image
#    ./image_to_vm.sh --from=../build/images/amd64-usr/latest/ --format=qemu_uefi --image_compression_formats none
#   Then, EXIT the SDK container (or run this on a different terminal):
#   ./run_local_tests.sh
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

  # Read by the mantle container.
  # The local directory ("pwd") will be mounted to /work/ in the container.
  cat > sdk_container/.env <<EOF
export QEMU_IMAGE_NAME=/work/__build__/images/images/${arch@Q}-usr/latest/flatcar_production_image.bin
export QEMU_UEFI_FIRMWARE=/work/__build__/images/images/${arch@Q}-usr/latest/flatcar_production_qemu_uefi_efi_code.qcow2
export QEMU_UEFI_OVMF_VARS=/work/__build__/images/images/${arch@Q}-usr/latest/flatcar_production_qemu_uefi_efi_vars.qcow2
export QEMU_UPDATE_PAYLOAD=/work/__build__/images/images/${arch@Q}-usr/latest/flatcar_test_update.gz
export PARALLEL_TESTS=${parallel@Q}
EOF

  export MAX_RETRIES=5
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
              kola list --platform qemu \
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
  if [[ -n "${tests}" ]] ; then
    echo "================================="
    echo "Running qemu_uefi tests"
    test_run "${arch}" qemu_uefi ${tests}
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
