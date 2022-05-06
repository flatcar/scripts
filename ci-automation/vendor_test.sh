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

# Unset all variables with ciavts_ prefix now.
unset -v "${!ciavts_@}"
