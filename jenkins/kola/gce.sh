#!/bin/bash
set -ex

rm -rf *.tap _kola_temp*

# If the OFFER is empty, it should be treated as the basic offering.
if [[ "${OFFER}" == "" ]]; then
  OFFER="basic"
fi

# Append the offer as oem suffix.
if [[ "${OFFER}" != "basic" ]]; then
  OEM_SUFFIX="_${OFFER}"
fi

# Create a name that includes the OFFER,
# but replace _ with -, as gcloud doesn't like it otherwise.
OEMNAME="${OFFER}-${BUILD_NUMBER}"
NAME=${OEMNAME//_/-}

bin/ore gcloud create-image \
    --board="${BOARD}" \
    --family="${NAME}" \
    --json-key="${GOOGLE_APPLICATION_CREDENTIALS}" \
    --source-root="${DOWNLOAD_ROOT}/boards" \
    --source-name=flatcar_production_gce${OEM_SUFFIX}.tar.gz \
    --version="${FLATCAR_VERSION}"

GCE_NAME="${NAME//[+.]/-}-${FLATCAR_VERSION//[+.]/-}"

trap 'bin/ore gcloud delete-images \
    --json-key="${GOOGLE_APPLICATION_CREDENTIALS}" \
    "${GCE_NAME}"' EXIT

if [[ "${KOLA_TESTS}" == "" ]]; then
  KOLA_TESTS="*"
fi

# Do not expand the kola test patterns globs
set -o noglob
timeout --signal=SIGQUIT 6h bin/kola run \
    --basename="${NAME}" \
    --gce-image="${GCE_NAME}" \
    --gce-json-key="${GOOGLE_APPLICATION_CREDENTIALS}" \
    --gce-machinetype="${GCE_MACHINE_TYPE}" \
    --parallel=4 \
    --platform=gce \
    --channel="${GROUP}" \
    --tapfile="${JOB_NAME##*/}.tap" \
    --torcx-manifest=torcx_manifest.json \
    ${KOLA_TESTS}
set +o noglob
