#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Helper script for test.sh to update the test failures text file.
# test.sh uses this to determine which tests need to re-run.
# This script is run within the SDK container.

set -euo pipefail

tapfile="$1"
image="$2"
retry="$3"
outfile="$4"

source ci-automation/tapfile_helper_lib.sh
tap_ingest_tapfile "${tapfile}" "${image}" "${retry}"
tap_failed_tests_for_vendor "${image}" | tee "${outfile}"
