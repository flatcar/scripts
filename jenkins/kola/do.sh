#!/bin/bash
set -ex

# JOB_NAME will not fit within the character limit
NAME="jenkins-${BUILD_NUMBER}"

set -o pipefail

if [[ "${DOWNLOAD_ROOT}" == gs://flatcar-jenkins-private/* ]]; then
  echo "Fetching google/cloud-sdk"
  docker pull google/cloud-sdk > /dev/null
  BUCKET_PATH="${DOWNLOAD_ROOT}/boards/${BOARD}/${FLATCAR_VERSION}/flatcar_production_digitalocean_image.bin.gz"
  IMAGE_URL="$(docker run --rm --net=host -v "${GOOGLE_APPLICATION_CREDENTIALS}:${GOOGLE_APPLICATION_CREDENTIALS}" google/cloud-sdk sh -c "python3 -m pip install pyopenssl > /dev/null; gsutil signurl -d 7d -r us ${GOOGLE_APPLICATION_CREDENTIALS} ${BUCKET_PATH} | grep -o 'https.*'")"
else
  BASE_URL="https://bucket.release.flatcar-linux.net/$(echo $DOWNLOAD_ROOT | sed 's|gs://||g')/boards/${BOARD}/${FLATCAR_VERSION}"
  IMAGE_URL="${BASE_URL}/flatcar_production_digitalocean_image.bin.gz"
fi

bin/ore do create-image \
    --config-file="${DIGITALOCEAN_CREDS}" \
    --region="${DO_REGION}" \
    --name="${NAME}" \
    --url="${IMAGE_URL}"

trap 'bin/ore do delete-image \
    --name="${NAME}" \
    --config-file="${DIGITALOCEAN_CREDS}"' EXIT

if [[ "${KOLA_TESTS}" == "" ]]; then
  KOLA_TESTS="*"
fi

# Do not expand the kola test patterns globs
set -o noglob
timeout --signal=SIGQUIT 4h bin/kola run \
    --do-size=${DO_MACHINE_SIZE} \
    --do-region=${DO_REGION} \
    --basename="${NAME}" \
    --do-config-file="${DIGITALOCEAN_CREDS}" \
    --do-image="${NAME}" \
    --parallel=8 \
    --platform=do \
    --channel="${GROUP}" \
    --tapfile="${JOB_NAME##*/}.tap" \
    --torcx-manifest=torcx_manifest.json \
    ${KOLA_TESTS}
set +o noglob
