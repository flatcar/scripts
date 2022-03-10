#!/bin/bash
set -ex

rm -rf *.tap _kola_temp*

NAME="jenkins-${JOB_NAME##*/}-${BUILD_NUMBER}"

if [[ "${AWS_INSTANCE_TYPE}" != "" ]]; then
  instance_type="${AWS_INSTANCE_TYPE}"
elif [[ "${BOARD}" == "arm64-usr" ]]; then
  instance_type="a1.large"
elif [[ "${BOARD}" == "amd64-usr" ]]; then
  instance_type="t3.small"
fi

# If the OFFER is empty, it should be treated as the basic offering.
if [[ "${OFFER}" == "" ]]; then
  OFFER="basic"
fi

# Append the offer as oem suffix.
if [[ "${OFFER}" != "basic" ]]; then
  OEM_SUFFIX="_${OFFER}"
fi

if [[ "${KOLA_TESTS}" == "" ]]; then
  KOLA_TESTS="*"
fi

if [[ "${AWS_AMI_ID}" == "" ]]; then
  [ -s verify.asc ] && verify_key=--verify-key=verify.asc || verify_key=
  mkdir -p tmp
  bin/cork download-image \
    --cache-dir=tmp \
    --json-key="${GOOGLE_APPLICATION_CREDENTIALS}" \
    --platform="aws${OEM_SUFFIX}" \
    --root="${DOWNLOAD_ROOT}/boards/${BOARD}/${FLATCAR_VERSION}" \
    --sanity-check=false --verify=true $verify_key
  bunzip2 "tmp/flatcar_production_ami_vmdk${OEM_SUFFIX}_image.vmdk.bz2"
  BUCKET="flatcar-kola-ami-import-${AWS_REGION}"
  trap 'bin/ore -d aws delete --region="${AWS_REGION}" --name="${NAME}" --ami-name="${NAME}" --file="tmp/flatcar_production_ami_vmdk${OEM_SUFFIX}_image.vmdk" --bucket "s3://${BUCKET}/${BOARD}/"; rm -r tmp/' EXIT
  bin/ore aws initialize --region="${AWS_REGION}" --bucket "${BUCKET}"
  AWS_AMI_ID=$(bin/ore aws upload --force --region="${AWS_REGION}" --name=${NAME} --ami-name="${NAME}" --ami-description="Flatcar Test ${NAME}" --file="tmp/flatcar_production_ami_vmdk${OEM_SUFFIX}_image.vmdk" --bucket "s3://${BUCKET}/${BOARD}/" | jq -r .HVM)
  echo "Created new AMI ${AWS_AMI_ID} (will be removed after testing)"
fi

# Run the cl.internet test on multiple machine types only if it should run in general
cl_internet_included="$(set -o noglob; bin/kola list --platform=aws --filter ${KOLA_TESTS} | { grep cl.internet || true ; } )"
if [[ "${BOARD}" == "amd64-usr" ]] && [[ "${cl_internet_included}" != ""  ]]; then
  for INSTANCE in m4.2xlarge; do
    (
    set +x
    OUTPUT=$(timeout --signal=SIGQUIT 6h bin/kola run \
    --parallel=8 \
    --basename="${NAME}" \
    --board="${BOARD}" \
    --aws-ami="${AWS_AMI_ID}" \
    --aws-region="${AWS_REGION}" \
    --aws-type="${INSTANCE}" \
    --aws-iam-profile="${AWS_IAM_PROFILE}" \
    --platform=aws \
    --channel="${GROUP}" \
    --offering="${OFFER}" \
    --tapfile="${JOB_NAME##*/}_validate_${INSTANCE}.tap" \
    --torcx-manifest=torcx_manifest.json \
    cl.internet 2>&1 || true)
    echo "=== START $INSTANCE ==="
    echo "${OUTPUT}" | sed "s/^/${INSTANCE}: /g"
    echo "=== END $INSTANCE ==="
    ) &
  done
fi

# Do not expand the kola test patterns globs
set -o noglob
timeout --signal=SIGQUIT 6h bin/kola run \
    --parallel=8 \
    --basename="${NAME}" \
    --board="${BOARD}" \
    --aws-ami="${AWS_AMI_ID}" \
    --aws-region="${AWS_REGION}" \
    --aws-type="${instance_type}" \
    --aws-iam-profile="${AWS_IAM_PROFILE}" \
    --platform=aws \
    --channel="${GROUP}" \
    --offering="${OFFER}" \
    --tapfile="${JOB_NAME##*/}.tap" \
    --torcx-manifest=torcx_manifest.json \
    ${KOLA_TESTS}
set +o noglob

# wait for the cl.internet test results
wait
