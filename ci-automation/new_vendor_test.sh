#!/bin/bash
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the azure vendor image.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

function generate_broken_test_tapfile {
    local error_msg="${1}"; shift
    echo "1..1" > "${CIA_TAPFILE}"
    echo "not ok - all ${CNV_PLATFORM:-(unknown platform, define CNV_PLATFORM!)} tests" >> "${CIA_TAPFILE}"
    echo "  ---" >> "${CIA_TAPFILE}"
    echo "  ERROR: ${error_msg}" | tee -a "${CIA_TAPFILE}"
    echo "  ..." >> "${CIA_TAPFILE}"
}

function generate_broken_test_tapfile_and_die {
    generate_broken_test_tapfile "${@}"
    break_retest_cycle
    exit 1
}

function generate_fail_tapfile() {
    local tapfile="${1}"; shift
    # rest of the args are test names
    echo "1..${#@}" >"${tapfile}"
    printf 'not ok - %s\n' "${@}" >>"${tapfile}"
}

function check_vars {
    if ! declare -p "${@}" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

function check_funcs {
    if ! declare -pF "${@}" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

CNVI_PHASE='pre-run'
CNVI_ALL_TESTS=( "${@}" )

function handle_setup_failures() {
    local error_msg
    case "${CNVI_PHASE}" in
        pre-run)
            error_msg='Something failed before running the setup'
            ;;
        setup)
            error_msg='Setup failed'
            ;;
        *)
            return 0;
            ;;
    esac
    # We didn't even reach kola invocation. Let's create a tapfile
    # with all the tests marked as a failure. This can be done only if
    # the query_kola_tests function and some output variables were
    # defined, though. That means that vendor tests should define them
    # as early as possible.
    if ! check_vars CNV_PLATFORM CNV_MAIN_INSTANCE CNV_EXTRA_INSTANCES CNV_EXTRA_INSTANCE_TESTS; then
        echo "handle_setup_failures: '${CIA_TESTSCRIPT}' did not define all the required variables to handle the setup failure"
        return 0
    fi

    local -a instance_tests
    local -a all_tests
    local other_tests_for_fgrep
    local instance

    function query_kola_tests {
        shift
        kola list --platform="${CNV_PLATFORM}" --filter "${@}"
    }

    instance_tests=()
    all_tests=()
    if [[ "${CIA_FIRST_RUN}" -eq 1 ]]; then
        # The "-t" option strips the delimiter. "mapfile" clears the
        # instance_tests array before assigning to it.
        mapfile -t instance_tests < <(run_query_kola_tests "${CNV_MAIN_INSTANCE}" "${CNVI_ALL_TESTS[@]}")
        all_tests+=( "${instance_tests[@]}" )

        other_tests_for_fgrep="$(printf '%s\n' "${CNVI_EXTRA_INSTANCE_TESTS[@]}")"
        for instance in "${CNVI_EXTRA_INSTANCES[@]}"; do
            mapfile -t instance_tests < <(run_query_kola_tests "${instance}" "${CNVI_ALL_TESTS[@]}" | grep --only-matching --fixed-strings "${other_tests_for_fgrep}" || :)
            all_tests+=( "${instance_tests[@]/#/extra_test.[${instance}].}" )
        done
    else
        all_tests=( "${CNVI_ALL_TESTS[@]}" )
    fi

    unset -f query_kola_tests

    generate_fail_tapfile "${CIA_TAPFILE}" "${all_tests[@]}"
    return 0
}
trap handle_setup_failures ERR

function ensure_arch {
    local arch
    for arch; do
        if [[ "${CIA_ARCH}" == "${arch}" ]]; then
            return 0
        fi
    done
    generate_broken_test_tapfile_and_die "${CIA_ARCH} tests not supported on ${CNV_PLATFORM}"
}

function ensure_tests {
    local kola_test
    for kola_test in "${CNVI_ALL_TESTS[@]}"; do
        if [[ "${kola_test}" = '*' ]]; then
            CNVI_ALL_TESTS=( "${@}" )
            return 0
        fi
    done
    local sup_kola_test ok
    for kola_test in "${CNVI_ALL_TESTS[@]}"; do
        ok=
        for sup_kola_test; do
            if [[ "${kola_test}" = "${sup_kola_test}" ]] || [[ "${kola_test}" = 'extra-test.['*"].${sup_kola_test}" ]]; then
                ok=x
                break
            fi
            if [[ -z "${ok}" ]]; then
                generate_broken_test_tapfile_and_die "'${kola_test}' test case is not supported in ${CIA_TESTSCRIPT}"
            fi
        done
    done
    return 0
}

function run_default_kola_tests {
    local variables=(
        CNV_MAIN_INSTANCE
        CNV_EXTRA_INSTANCES
        CNV_EXTRA_INSTANCE_TESTS
        CNV_PLATFORM
    )
    local funcs=(
        get_kola_args
        failible_setup
    )
    local f

    if ! check_vars "${variables[@]}"; then
        generate_broken_test_tapfile_and_die "At least one of ${variables[@]} variables is not defined."
    fi
    if ! check_funcs "${funcs[@]}"; then
        generate_broken_test_tapfile_and_die "At least one of ${funcs[@]} functions is not defined."
    fi
    for f in query_kola_tests run_kola_tests; do
        if check_funcs "${f}"; then
            generate_broken_test_tapfile_and_die "Function ${f} can't be defined, it will be clobbered by us."
        fi
    done

    if [[ -n "${CNV_SUPPORTED_TESTS[@]:-}" ]]; then
        ensure_tests "${CNV_SUPPORTED_TESTS[@]}"
    fi

    if [[ -n "${CNV_SUPPORTED_ARCH[@]:-}" ]]; then
        ensure_arch "${CNV_SUPPORTED_ARCH[@]}"
    fi

    CNVI_PHASE='setup'
    failible_setup
    CNVI_PHASE='run'

    function query_kola_tests {
        shift
        kola list --platform="${CNV_PLATFORM}" --filter "${@}"
    }

    function run_kola_tests {
        local instance_type="${1}"; shift
        local instance_tapfile="${1}"; shift
        local -a kola_args kola_tests

        mapfile -t kola_args < <(get_kola_args "${instance_type}")

        kola_tests=( "${@}" )
        kola_run "${tapfile}" kola_args kola_tests
    }

    # Skip the set -x set +e setup done by vendor_test.sh, we are
    # doing a verbose call to kola ourselves.
    local CIA_SKIP_KOLA_TESTS_SHELL_WRAPPER=x
    run_kola_tests_on_instances \
        "${CNV_MAIN_INSTANCE}" \
        "${CIA_TAPFILE}" \
        "${CIA_FIRST_RUN}" \
        "${CNV_EXTRA_INSTANCES[@]}" \
        -- \
        "${CNV_EXTRA_INSTANCE_TESTS[@]}" \
        -- \
        "${CNVI_ALL_TESTS[@]}"

    unset -f run_kola_tests query_kola_tests
}

function kola_run() {
    local tapfile="${1}"; shift
    local kola_args_var_name="${1}"; shift
    local kola_tests_var_name="${1}"; shift
    local -a common_opts kola_cmd

    local -n kola_args_var="${kola_args_var_name}"
    local -n kola_tests_var="${kola_tests_var_name}"

    common_opts=(
        --board="${CIA_ARCH}-usr"
        --tapfile="${tapfile}"
        --torcx-manifest="${CIA_TORCX_MANIFEST}"
        --channel="${CIA_CHANNEL}"
        --platform="${CNV_PLATFORM}"
    )
    kola_cmd=()
    if [[ -n "${CNV_TIMEOUT:-}" ]]; then
        kola_cmd+=( timeout --signal=SIGQUIT "${CNV_TIMEOUT}" )
    fi
    kola_cmd+=(
        kola run
        "${common_opts[@]}"
        "${kola_args_var[@]}"
        "${kola_tests_var[@]}"
    )
    printf "%q" "${kola_cmd[@]}"; printf '\n'
    "${kola_cmd[@]}" || :
    if [[ ! -e "${tapfile}" ]]; then
        generate_fail_tapfile "${tapfile}" "${kola_tests_var[@]}"
    fi
}
