#!/bin/bash
# Copyright (c) 2022 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the test non-vendor non-image.
# This script is supposed to run in the mantle container.

source ci-automation/new_vendor_test.sh

CNV_MAIN_INSTANCE='default'
CNV_EXTRA_INSTANCES=( 'extra1' 'extra2' )
CNV_EXTRA_INSTANCE_TESTS=( 'cl.internet' )
CNV_PLATFORM=test
CNV_TIMEOUT=10s

function failible_test {
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
}

get_kola_args() {
    local instance_type="${1}"; shift
    local -a args
    args=(
        --parallel=42
        --platform=test
    )
    printf '%s\n' "${args[@]}"
}

run_default_kola_tests
