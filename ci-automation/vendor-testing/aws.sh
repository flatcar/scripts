#!/bin/bash
# Copyright (c) 2022 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -euo pipefail

# Test execution script for the qemu vendor image.
# This script is supposed to run in the SDK container.

work_dir="$1"; shift
arch="$1"; shift
vernum="$1"; shift
tapfile="$1"; shift

AWS_BOARD="${arch}-usr"
AWS_CHANNEL="$(get_git_channel)"
AWS_IMAGE_NAME="ci-${vernum}"

if [[ "${arch}" == "arm64-usr" ]]; then
    AWS_INSTANCE_TYPE="a1.large"
fi

# $@ now contains tests / test patterns to run

source ci-automation/ci_automation_common.sh

mkdir -p "${work_dir}"
cd "${work_dir}"

testscript="$(basename "$0")"

if [[ "${AWS_AMI_ID}" == "" ]]; then
    [ -s verify.asc ] && verify_key=--verify-key=verify.asc || verify_key=

    echo "++++ ${testscript}: downloading flatcar_production_ami_vmdk${AWS_OEM_SUFFIX}_image.vmdk.bz2 for ${vernum} (${arch}) ++++"
    copy_from_buildcache "images/${arch}/${vernum}/flatcar_production_ami_vmdk${AWS_OEM_SUFFIX}_image.vmdk.bz2" .

    bunzip2 "${work_dir}/flatcar_production_ami_vmdk${AWS_OEM_SUFFIX}_image.vmdk.bz2"

    # FIXME: need to check if it is ok to run ore
    AWS_BUCKET="flatcar-kola-ami-import-${AWS_REGION}"
    trap 'bin/ore -d aws delete --region="${AWS_REGION}" --name="${AWS_IMAGE_NAME}" --ami-name="${AWS_IMAGE_NAME}" --file="${work_dir}/flatcar_production_ami_vmdk${AWS_OEM_SUFFIX}_image.vmdk" --bucket "s3://${AWS_BUCKET}/${AWS_BOARD}/"; rm -r ${work_dir}/' EXIT
    bin/ore aws initialize --region="${AWS_REGION}" --bucket "${AWS_BUCKET}"
    AWS_AMI_ID=$(bin/ore aws upload --force --region="${AWS_REGION}" --name=${AWS_IMAGE_NAME} --ami-name="${AWS_IMAGE_NAME}" --ami- description="Flatcar Test ${AWS_IMAGE_NAME}" --file="${work_dir}/flatcar_production_ami_vmdk${AWS_OEM_SUFFIX}_image.vmdk" --bucket  "s3://${AWS_BUCKET}/${AWS_BOARD}/" | jq -r .HVM)
    echo "Created new AMI ${AWS_AMI_ID} (will be removed after testing)"
fi


# AWS timeout
timeout=6h

set -x
set -o noglob

sudo timeout --signal=SIGQUIT ${timeout} bin/kola run \
    --board="${AWS_BOARD}" \
    --basename="${AWS_IMAGE_NAME}" \
    --channel="${AWS_CHANNEL}" \
    --offering="${AWS_OFFER}" \
    --parallel=${PARALLEL_TESTS} \
    --platform=aws \
    --aws-ami="${AWS_AMI_ID}" \
    --aws-region="${AWS_REGION}" \
    --aws-type="${AWS_INSTANCE_TYPE}" \
    --aws-iam-profile="${AWS_IAM_PROFILE}" \
    --tapfile="${tapfile}" \
    --torcx-manifest=torcx_manifest.json \
    $@

set +o noglob
set +x
