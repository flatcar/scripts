#!/bin/bash
# Copyright (c) 2022 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the AWS vendor image.
# This script is supposed to run in the mantle container.

source ci-automation/new_vendor_test.sh

cvt_board="${CIA_ARCH}-usr"
cvt_escaped_vernum="${CIA_VERNUM//+/-}"
cvt_image_name="ci-${cvt_escaped_vernum}-${CIA_ARCH}"
cvt_aws_instance_type_var="AWS_${CIA_ARCH}_INSTANCE_TYPE"
cvt_aws_instance_type="${!cvt_aws_instance_type_var}"
cvt_more_aws_instance_types_var="AWS_${CIA_ARCH}_MORE_INSTANCE_TYPES"
mapfile -t cvt_more_aws_instance_types < <(tr ' ' '\n' <<<"${!cvt_more_aws_instance_types_var}")

CNV_MAIN_INSTANCE="${cvt_aws_instance_type}"
CNV_EXTRA_INSTANCES=( "${cvt_more_aws_instance_types[@]}" )
CNV_EXTRA_INSTANCE_TESTS=( 'cl.internet' )
CNV_PLATFORM=aws
CNV_TIMEOUT=6h

function failible_setup {
    local image_file='flatcar_production_ami_image.bin'
    local tarball="${image_file}.bz2"
    local aws_bucket
    local aws_s3_path

    if [[ "${AWS_AMI_ID}" == "" ]]; then
        if [[ -f "${image_file}" ]]; then
            echo "++++ ${CIA_TESTSCRIPT}: using existing ${image_file} for ${CIA_VERNUM} (${CIA_ARCH}) ++++"
        else
            echo "++++ ${CIA_TESTSCRIPT}: downloading ${tarball} for ${CIA_VERNUM} (${CIA_ARCH}) ++++"
            copy_from_buildcache "images/${CIA_ARCH}/${CIA_VERNUM}/${tarball}" .
            lbunzip2 "${tarball}"
        fi

        aws_bucket="flatcar-kola-ami-import-${AWS_REGION}"
        aws_s3_path="s3://${aws_bucket}/${cvt_escaped_vernum}/${cvt_board}/"
        trap 'ore -d aws delete --region="${AWS_REGION}" --board="${cvt_board}" --name="${cvt_image_name}" --ami-name="${cvt_image_name}" --file="${image_file}" --bucket "${aws_s3_path}"' EXIT
        ore aws initialize --region="${AWS_REGION}" --bucket "${aws_bucket}"
        AWS_AMI_ID=$(ore aws upload --force --region="${AWS_REGION}" --board="${cvt_board}" --name="${cvt_image_name}" --ami-name="${cvt_image_name}" --ami-description="Flatcar Test ${cvt_image_name}" --file="${image_file}" --object-format=RAW --force --bucket "${aws_s3_path}" | jq -r .HVM)
        echo "++++ ${CIA_TESTSCRIPT}: created new AMI ${AWS_AMI_ID} (will be removed after testing) ++++"
    fi
}

function get_kola_args {
    local instance_type="${1}"; shift

    local args=(
        --basename="${cvt_image_name}" \
        --offering='basic' \
        --parallel="${AWS_PARALLEL}" \
        --aws-ami="${AWS_AMI_ID}" \
        --aws-region="${AWS_REGION}" \
        --aws-type="${instance_type}" \
        --aws-iam-profile="${AWS_IAM_PROFILE}"
    )
    printf '%s\n' "${args[@]}"
}

# these are set in ci-config.env
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

run_default_kola_tests
