#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Helper script for test.sh to update the test failures text file.
# test.sh uses this to determine which tests need to re-run.
# This script is run within the SDK container.

set -euo pipefail

arch="$1"
vernum="$2"
image="$3"
retry="$4"
tapfile="$5"
failfile="$6"
merged_summary="$7"
merged_detailed="$8"

source ci-automation/ci-config.env
source ci-automation/tapfile_helper_lib.sh
tap_ingest_tapfile "${tapfile}" "${image}" "${retry}"
tap_failed_tests_for_vendor "${image}" > "${failfile}"

for format in "${TEST_REPORT_FORMATS[@]}"; do
    tap_generate_report "${arch}" "${vernum}" "${format}" > "${merged_summary}.${format}"
    tap_generate_report "${arch}" "${vernum}" "${format}" "true" > "${merged_detailed}.${format}"
done
