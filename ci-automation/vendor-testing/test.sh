#!/bin/bash
# Copyright (c) 2022 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the test non-vendor non-image.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

# $@ now contains tests / test patterns to run

CIA_OUTPUT_MAIN_INSTANCE='default'
CIA_OUTPUT_ALL_TESTS=( "${@}" )
CIA_OUTPUT_EXTRA_INSTANCES=( 'extra1' 'extra2' )
CIA_OUTPUT_EXTRA_INSTANCE_TESTS=( 'cl.internet' )
CIA_OUTPUT_TIMEOUT=10s

query_kola_tests() {
    shift; # ignore the instance type
    kola list --platform=test --filter "${@}"
}

if [[ ! -d path-override ]]; then
    mkdir path-override
fi
if [[ ! -e 'path-override/kola' ]]; then
   cp "${CIA_VENDOR_SCRIPTS_DIR}/test-kola.sh" 'path-override/kola'
fi
if [[ ! -x 'path-override/kola' ]]; then
    chmod a+x 'path-override/kola'
fi
export PATH="${PWD}/path-override:${PATH}"

for test_name; do
    case "${test_name}" in
        'fail.setup')
            echo 'failing setup'
            false
            ;;
    esac
done

run_kola_tests() {
    local instance_type="${1}"; shift

    kola_run \
        --parallel=42 \
        --platform=test
}

run_default_kola_tests
