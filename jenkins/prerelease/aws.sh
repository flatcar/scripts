#!/bin/bash
set -ex

rm -f ami.properties images.json

[ -s verify.asc ] && verify_key=--verify-key=verify.asc || verify_key=

bin/plume pre-release --force \
    --debug \
    --platform=aws \
    --aws-credentials="${AWS_CREDENTIALS}" \
    --gce-json-key="${GOOGLE_APPLICATION_CREDENTIALS}" \
    --board="${BOARD}" \
    --channel="${CHANNEL}" \
    --version="${FLATCAR_VERSION}" \
    --write-image-list=images.json \
    $verify_key

hvm_ami_id=$(jq -r '.aws.amis[]|select(.name == "'"${AWS_REGION}"'").hvm' images.json)

tee ami.properties << EOF
HVM_AMI_ID = ${hvm_ami_id:?}
EOF
