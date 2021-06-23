#!/bin/bash
set -ex

# JOB_NAME will not fit within the character limit
NAME="jenkins-${BUILD_NUMBER}"

[ -s verify.asc ] && verify_key=--verify-key=verify.asc || verify_key=

mkdir -p tmp
bin/cork download-image \
    --cache-dir=tmp \
    --json-key="${GOOGLE_APPLICATION_CREDENTIALS}" \
    --platform=esx \
    --root="${DOWNLOAD_ROOT}/boards/${BOARD}/${FLATCAR_VERSION}" \
    --verify=true $verify_key

trap 'bin/ore esx --esx-config-file "${VMWARE_ESX_CREDS}" remove-vms \
    --pattern "${NAME}*" || true' EXIT

if [[ "${KOLA_TESTS}" == "" ]]; then
  KOLA_TESTS="*"
fi

# Delete every VM that is running because we'll use all available spots
bin/ore esx --esx-config-file "${VMWARE_ESX_CREDS}" remove-vms || true

# Do not expand the kola test patterns globs
set -o noglob
timeout --signal=SIGQUIT 2h bin/kola run \
    --basename="${NAME}" \
    --esx-config-file "${VMWARE_ESX_CREDS}" \
    --esx-ova-path tmp/flatcar_production_vmware_ova.ova \
    --parallel=4 \
    --platform=esx \
    --channel="${GROUP}" \
    --tapfile="${JOB_NAME##*/}.tap" \
    --torcx-manifest=torcx_manifest.json \
    ${KOLA_TESTS}
set +o noglob
sudo rm -rf tmp
