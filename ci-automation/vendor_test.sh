# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Vendor test helper script. Sourced by vendor tests. Does some
# initial setup.
#
#
# The initial setup consist of creating the vendor working directory
# for the vendor test script, specifying the variables described below
# and changing the current working directory to the vendor working
# directory.
#
#
# The vendor test script is expected to keep all artifacts it produces
# in its current working directory.
#
#
# The script specifies the following variables for the vendor test
# script to use:
#
# CIA_VERNUM:
#   Image version. In case of developer builds it comes with a suffix,
#   so it looks like "3217.0.0+nightly-20220422-0155". For release
#   builds the version will be without suffix, so it looks like
#   "3217.0.0". Whether the build is a release or a developer one is
#   reflected in CIA_BUILD_TYPE variable described below.
#
# CIA_ARCH:
#   Architecture to test. Currently it is either "amd64" or "arm64".
#
# CIA_TAPFILE:
#   Where the TAP reports should be written. Usually just passed to
#   kola throught the --tapfile parameter.
#
# CIA_CHANNEL:
#   A channel. Either "alpha", "beta", "stable" or "lts". Used to find
#   the last release for the update check.
#
# CIA_TESTSCRIPT:
#   Name of the vendor script. May be useful in some messages.
#
# CIA_GIT_VERSION:
#   The most recent tag for the current commit.
#
# CIA_BUILD_TYPE:
#   It's either "release" or "developer", based on the CIA_VERNUM
#   variable.
#
# CIA_TORCX_MANIFEST:
#   Path to the Torcx manifest. Usually passed to kola through the
#   --torcx-manifest parameter.
#
# CIA_FIRST_RUN:
#   1 if this is a first run, 0 if it is a rerun of failed tests.
#
#
# After this script is sourced, the parameters in ${@} specify test
# cases / test case patterns to run.


# "ciavts" stands for Continuous Integration Automation Vendor Test
# Setup. This prefix is used to easily unset all the variables with
# this prefix before leaving this file.

ciavts_main_work_dir="${1}"; shift
ciavts_work_dir="${1}"; shift
ciavts_arch="${1}"; shift
ciavts_vernum="${1}"; shift
ciavts_tapfile="${1}"; shift

# $@ now contains tests / test patterns to run

source ci-automation/ci_automation_common.sh

mkdir -p "${ciavts_work_dir}"

ciavts_testscript=$(basename "${0}")
ciavts_git_version=$(cat "${ciavts_main_work_dir}/git_version")
ciavts_channel=$(cat "${ciavts_main_work_dir}/git_channel")
if [[ "${ciavts_channel}" = 'developer' ]]; then
    ciavts_channel='alpha'
fi
# If vernum is like 3200.0.0+whatever, it's a developer build,
# otherwise it's a release build.
ciavts_type='developer'
if [[ "${ciavts_vernum%%+*}" = "${ciavts_vernum}" ]]; then
    ciavts_type='release'
fi

# Make these paths absolute to avoid problems when changing
# directories.
ciavts_tapfile="${PWD}/${ciavts_work_dir}/${ciavts_tapfile}"
ciavts_torcx_manifest="${PWD}/${ciavts_main_work_dir}/torcx_manifest.json"

ciavts_first_run=0
if [[ -f "${ciavts_main_work_dir}/first_run" ]]; then
    ciavts_first_run=1
fi

echo "++++ Running ${ciavts_testscript} inside ${ciavts_work_dir} ++++"

cd "${ciavts_work_dir}"

CIA_VERNUM="${ciavts_vernum}"
CIA_ARCH="${ciavts_arch}"
CIA_TAPFILE="${ciavts_tapfile}"
CIA_CHANNEL="${ciavts_channel}"
CIA_TESTSCRIPT="${ciavts_testscript}"
CIA_GIT_VERSION="${ciavts_git_version}"
CIA_BUILD_TYPE="${ciavts_type}"
CIA_TORCX_MANIFEST="${ciavts_torcx_manifest}"
CIA_FIRST_RUN="${ciavts_first_run}"

# Unset all variables with ciavts_ prefix now.
unset -v "${!ciavts_@}"

trap handle_flaky_setup ERR
function handle_flaky_setup() {
    if [[ -e "${CIA_TAPFILE}" ]]; then
        # Tests had their run, tapfile was created, nothing to do
        # here.
        return 0
    fi
    # Tapfile wasn't created, which means that we didn't even reach
    # kola invocation. Let's create a tapfile with all the tests
    # marked as a failure. This can be done only if the
    # query_kola_tests function and some output variables were
    # defined, though. That means that vendor tests should define them
    # as early as possible.
    if ! declare -p CIA_OUTPUT_MAIN_INSTANCE CIA_OUTPUT_ALL_TESTS CIA_OUTPUT_EXTRA_INSTANCES CIA_OUTPUT_EXTRA_INSTANCE_TESTS >/dev/null 2>&1; then
        echo "handle_flaky_setup: '${CIA_TESTSCRIPT}' did not define all the required variables to handle the setup failure"
        return 0
    fi
    if [[ "$(type -t query_kola_tests || true)" != 'function' ]]; then
        echo "handle_flaky_setup: '${CIA_TESTSCRIPT}' did not define the query_kola_tests function to handle the setup failure"
        return 0
    fi

    local -a instance_tests
    local -a all_tests
    local other_tests_for_fgrep
    local instance

    instance_tests=()
    all_tests=()
    if [[ "${CIA_FIRST_RUN}" -eq 1 ]]; then
        # The "-t" option strips the delimiter. "mapfile" clears the
        # instance_tests array before assigning to it.
        mapfile -t instance_tests < <(run_query_kola_tests "${CIA_OUTPUT_MAIN_INSTANCE}" "${CIA_OUTPUT_ALL_TESTS[@]}")
        all_tests+=( "${instance_tests[@]}" )

        other_tests_for_fgrep="$(printf '%s\n' "${CIA_OUTPUT_EXTRA_INSTANCE_TESTS[@]}")"
        for instance in "${CIA_OUTPUT_EXTRA_INSTANCES[@]}"; do
            mapfile -t instance_tests < <(run_query_kola_tests "${instance}" "${CIA_OUTPUT_ALL_TESTS[@]}" | grep --only-matching --fixed-strings "${other_tests_for_fgrep}" || :)
            all_tests+=( "${instance_tests[@]/#/extra_test.[${instance}].}" )
        done
    else
        all_tests=( "${CIA_OUTPUT_ALL_TESTS[@]}" )
    fi

    echo "1..${#all_tests[@]}" >"${CIA_TAPFILE}"
    printf 'not ok - %s\n' "${all_tests[@]}" >>"${CIA_TAPFILE}"
    return 0
}

# Prefixes all test names in the tap file with a given prefix, so the
# test name like "cl.basic" will become "extra-test.[${prefix}].cl.basic".
#
# Typical use:
#   prefix_tap_file "${instance_type}" "${tapfile}"
#
# Parameters:
# 1 - prefix
# 2 - tap file, modified in place
function prefix_tap_file() {
    local prefix="${1}"; shift
    local tap_file="${1}"; shift
    # drop the dots from prefix
    local actual_prefix="extra-test.[${prefix}]."

    sed --in-place --expression 's/^\(\s*\(not\)\?\s*ok[^-]*\s*-\s*\)\(\S\)/\1'"${actual_prefix}"'\3/g' "${tap_file}"
}

# Filters the test names, so it puts only the real names of the
# prefixed tests into the chosen variable. For example for prefix
# "foo", it will ignore the test name like "cl.basic", but will print
# "cl.internet" for a test name like "extra-test.[foo].cl.internet".
# "*" is treated specially - it will be inserted into the chosen
# variable if it is passed.
#
# Typical use:
#   filter_prefixed_tests tests_to_run "${instance_type}" "${@}"
#   if [[ "${#tests_to_run[@]}" -gt 0 ]]; then …; fi
#
# Parameters:
# 1 - name of an array variable where the filtering results will be stored
# 2 - prefix
# @ - test names
function filter_prefixed_tests() {
    local var_name="${1}"; shift
    local prefix="${1}"; shift
    # rest of the parameters are test names
    local -n results="${var_name}"
    local name
    local stripped_name
    # clear the array, so it will contain results of current filtering
    # only
    results=()
    for name; do
        stripped_name="${name#extra-test.\[${prefix}\].}"
        if [[ "${stripped_name}" != "${name}" ]]; then
            results+=( "${stripped_name}" )
            continue
        elif [[ "${name}" = '*' ]]; then
            results+=( '*' )
        fi
    done
}

# Filters out the extra tests from the passed test names. Ignored test
# names begin with "extra-test.". The results of the filtering are
# inserted into the chosen variable.
#
# Typical use:
#   filter_out_prefixed_tests tests_to_run "${@}"
#   if [[ "${#tests_to_run[@]}" -gt 0 ]]; then …; fi
#
# Parameters:
# 1 - name of an array variable where the filtering results will be stored
# @ - test names
function filter_out_prefixed_tests() {
    local var_name="${1}"; shift
    local -n results="${var_name}"
    local name
    # clear the array, so it will contain results of current filtering
    # only
    results=()
    for name; do
        if [[ "${name#extra-test.}" = "${name}" ]]; then
            results+=( "${name}" )
        fi
    done
}

# Merges into the first (main) tap file the contents of other tap
# files. It is very simple - the function assumes that all the tap
# files begin with a line like:
#
# 1..${number_of_tests}
#
# Other lines that are processed should begin like:
#
# (not)? ok - ${test_name}
#
# Any other lines are copied verbatim.
#
# The other tap files should already be preprocessed by
# prefix_tap_file to avoid duplicated test names.
#
# Typical use:
#   merge_tap_files "${tap_file}" extra-validation-*.tap
#   rm -f extra-validation-*.tap
#
# Parameters:
# 1 - main tap file
# @ - other tap files
function merge_tap_files() {
    local main_tap_file="${1}"; shift
    # rest of the parameters are other tap files

    local main_test_count=0
    if [[ -f "${main_tap_file}" ]]; then
        main_test_count=$(head --lines=1 "${main_tap_file}" | grep --only-matching '[0-9]\+$')
    fi
    local other_test_count
    local other_tap_file
    local tmp_tap_file="${main_tap_file}.mtf.tmp"
    for other_tap_file; do
        if [[ ! -f "${other_tap_file}" ]]; then
            continue
        fi
        other_test_count=$(head --lines=1 "${other_tap_file}" | grep --only-matching '[0-9]\+$' || echo 0 )
        ((main_test_count+=other_test_count))
    done
    echo "1..${main_test_count}" >"${tmp_tap_file}"
    if [[ -f "${main_tap_file}" ]]; then
        tail --lines=+2 "${main_tap_file}" >>"${tmp_tap_file}"
    fi
    for other_tap_file; do
        if [[ ! -f "${other_tap_file}" ]]; then
            continue
        fi
        tail --lines=+2 "${other_tap_file}" >>"${tmp_tap_file}"
    done
    mv --force "${tmp_tap_file}" "${main_tap_file}"
}

# Runs or reruns the tests on the main instance and other
# instances. Other instances usually run a subset of tests only.
#
# For this function to work, the caller needs to define two functions
# beforehand:
#
# run_kola_tests that takes the following parameters:
# 1 - instance type
# 2 - tap file
# @ - tests to run
#
# query_kola_tests that takes the following parameters:
# 1 - instance type
# @ - tests to run
# This function should print the names of the tests to run. Every line
# of the output should have one test name to run. Any other cruft in
# the line will be ignored.
#
# Typical use:
# function run_kola_tests() {
#     local instance_type="${1}"; shift
#     local tap_file="${1}"; shift
#     kola run … "${@}"
# }
#
# function query_kola_tests() {
#     local instance_type="${1}"; shift
#     kola list … "${@}"
# }
#
# args=(
#     "${main_instance}"
#     "${CIA_TAPFILE}"
#     "${CIA_FIRST_RUN}"
#     "${other_instance_types[@]}"
#     '--'
#     'cl.internet'
#     '--'
#     "${tests_to_run[@]}"
# )
# run_kola_tests_on_instances "${args[@]}"
#
# Parameters:
# 1 - main instance type - there all the tests are being run
# 2 - main tap file
# 3 - if this is first run (1 if it is, 0 if it is a rerun)
# @ - other instance types followed by double dash (--) followed by
#     test names for other instances to filter from the tests to be
#     run followed by double dash, followed by tests to be run or
#     rerun
function run_kola_tests_on_instances() {
    local main_instance_type="${1}"; shift
    local main_tapfile="${1}"; shift
    local is_first_run="${1}"; shift
    local other_instance_types=()
    local other_tests=()
    local arg

    while [[ "${#}" -gt 0 ]]; do
        arg="${1}"; shift
        if [[ "${arg}" = '--' ]]; then
            break
        fi
        other_instance_types+=( "${arg}" )
    done

    while [[ "${#}" -gt 0 ]]; do
        arg="${1}"; shift
        if [[ "${arg}" = '--' ]]; then
            break
        fi
        other_tests+=( "${arg}" )
    done

    # rest of the parameters are tests to be run or rerun

    local instance_type
    local instance_tests=()
    local tests_on_instances_running=0
    local other_tests_for_fgrep
    other_tests_for_fgrep="$(printf '%s\n' "${other_tests[@]}")"

    for instance_type in "${other_instance_types[@]}"; do
        # On first run we usually pass the canonical test names like
        # cl.basic, cl.internet or *, so we decide which tests should
        # be run on the other instances based on this list. On the
        # other hand, the rerun will contain names of the failed tests
        # only, and those are specific - if a test failed on the main
        # instance, the name of the test will be like cl.basic; if a
        # test failed on other instance, the name of the test will be
        # like extra-test.[…].cl.basic. So in case of reruns, we want
        # to filter the extra tests first then we decide which tests
        # should be run.
        if [[ "${is_first_run}" -eq 1 ]]; then
            mapfile -t instance_tests < <(run_query_kola_tests "${instance_type}" "${@}" | grep --only-matching --fixed-strings "${other_tests_for_fgrep}" || :)
        else
            filter_prefixed_tests instance_tests "${instance_type}" "${@}"
        fi
        if [[ "${#instance_tests[@]}" -gt 0 ]]; then
            tests_on_instances_running=1
            (
                local instance_tapfile="instance_${instance_type}_validate.tap"
                set +e
                set -x
                local output
                output=$(run_kola_tests "${instance_type}" "${instance_tapfile}" "${instance_tests[@]}" 2>&1)
                set +x
                set -e
                local escaped_instance_type
                escaped_instance_type="$(sed -e 's/[\/&]/\\&/g' <<<"${instance_type}")"
                printf "=== START ${instance_type} ===\n%s\n=== END ${instance_type} ===\n" "$(sed -e "s/^/${escaped_instance_type}: /g" <<<"${output}")"
                prefix_tap_file "${instance_type}" "${instance_tapfile}"
            ) &
        fi
    done

    local main_tests=()

    filter_out_prefixed_tests main_tests "${@}"
    if [[ "${#main_tests[@]}" -gt 0 ]]; then
        # run in a subshell, so the set -x and set +e do not pollute
        # the outer environment
        (
            set +e
            set -x
            run_kola_tests "${main_instance_type}" "${main_tapfile}" "${main_tests[@]}"
            true
        )
    fi

    if [[ "${tests_on_instances_running}" -eq 1 ]]; then
        wait
        merge_tap_files "${main_tapfile}" 'instance_'*'_validate.tap'
        rm -f 'instance_'*'_validate.tap'
    fi
}

# Runs the user-defined query_kola_tests callback and massages its
# output so only a list of tests is printed.
function run_query_kola_tests() {
    # The "-n +3" option will skip the table header and the empty line
    # that follows it.
    query_kola_tests "${@}" | tail -n +3 | awk '{ print $1 }'
}

# Invokes run_kola_tests_on_instances with arguments from various CIA_
# variables. Will only work if the vendor test specifies the necessary
# output variables.
function run_default_kola_tests() {
    if ! declare -p CIA_OUTPUT_MAIN_INSTANCE CIA_OUTPUT_ALL_TESTS CIA_OUTPUT_EXTRA_INSTANCES CIA_OUTPUT_EXTRA_INSTANCE_TESTS >/dev/null 2>&1; then
        echo "1..1" > "${CIA_TAPFILE}"
        echo "not ok - all the tests for ${CIA_TESTSCRIPT}" >> "${CIA_TAPFILE}"
        echo "  ---" >> "${CIA_TAPFILE}"
        echo "  ERROR: ${CIA_TESTSCRIPT} tried to invoke run_default_kola_tests but didn't specify the necessary variables" | tee -a "${CIA_TAPFILE}"
        echo "  ..." >> "${CIA_TAPFILE}"
        break_retest_cycle
        return 1
    fi
    run_kola_tests_on_instances \
        "${CIA_OUTPUT_MAIN_INSTANCE}" \
        "${CIA_TAPFILE}" \
        "${CIA_FIRST_RUN}" \
        "${CIA_OUTPUT_EXTRA_INSTANCES[@]}" \
        '--' \
        "${CIA_OUTPUT_EXTRA_INSTANCE_TESTS[@]}" \
        '--' \
        "${CIA_OUTPUT_ALL_TESTS[@]}"
}
