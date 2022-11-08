#!/bin/bash
# Copyright (c) 2022 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the AWS vendor image.
# This script is supposed to run in the mantle container.

source ci-automation/vendor_test.sh

board="${CIA_ARCH}-usr"
escaped_vernum="${CIA_VERNUM//+/-}"
image_name="ci-${escaped_vernum}-${CIA_ARCH}"
aws_instance_type_var="AWS_${CIA_ARCH}_INSTANCE_TYPE"
aws_instance_type="${!aws_instance_type_var}"
more_aws_instance_types_var="AWS_${CIA_ARCH}_MORE_INSTANCE_TYPES"
mapfile -t more_aws_instance_types < <(tr ' ' '\n' <<<"${!more_aws_instance_types_var}")

image_file='flatcar_production_ami_image.bin'
tarball="${image_file}.bz2"

if [[ "${AWS_AMI_ID}" == "" ]]; then
    if [[ -f "${image_file}" ]]; then
        echo "++++ ${CIA_TESTSCRIPT}: using existing ${image_file} for ${CIA_VERNUM} (${CIA_ARCH}) ++++"
    else
        echo "++++ ${CIA_TESTSCRIPT}: downloading ${tarball} for ${CIA_VERNUM} (${CIA_ARCH}) ++++"
        copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/${tarball}" .
        lbunzip2 "${tarball}"
    fi

    aws_bucket="flatcar-kola-ami-import-${AWS_REGION}"
    aws_s3_path="s3://${aws_bucket}/${escaped_vernum}/${board}/"
    trap 'ore -d aws delete --region="${AWS_REGION}" --board="${board}" --name="${image_name}" --ami-name="${image_name}" --file="${image_file}" --bucket "${aws_s3_path}"' EXIT
    ore aws initialize --region="${AWS_REGION}" --bucket "${aws_bucket}"
    AWS_AMI_ID=$(ore aws upload --force --region="${AWS_REGION}" --board="${board}" --name="${image_name}" --ami-name="${image_name}" --ami-description="Flatcar Test ${image_name}" --file="${image_file}" --object-format=RAW --force --bucket "${aws_s3_path}" | jq -r .HVM)
    echo "++++ ${CIA_TESTSCRIPT}: created new AMI ${AWS_AMI_ID} (will be removed after testing) ++++"
fi

run_kola_tests() {
    local instance_type="${1}"; shift
    local instance_tapfile="${1}"; shift

    timeout --signal=SIGQUIT 6h \
        kola run \
         --board="${board}" \
         --basename="${image_name}" \
         --channel="${CIA_CHANNEL}" \
         --offering='basic' \
         --parallel="${AWS_PARALLEL}" \
         --platform=aws \
         --aws-ami="${AWS_AMI_ID}" \
         --aws-region="${AWS_REGION}" \
         --aws-type="${instance_type}" \
         --aws-iam-profile="${AWS_IAM_PROFILE}" \
         --tapfile="${instance_tapfile}" \
         --torcx-manifest="${CIA_TORCX_MANIFEST}" \
         "${@}"
}

query_kola_tests() {
    shift; # ignore the instance type
    kola list --platform=aws --filter "${@}"
}

# these are set in ci-config.env
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

run_kola_tests_on_instances \
    "${aws_instance_type}" \
    "${CIA_TAPFILE}" \
    "${CIA_FIRST_RUN}" \
    "${more_aws_instance_types[@]}" \
    '--' \
    'cl.internet' \
    '--' \
    "${@}"
