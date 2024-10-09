#!/bin/bash
set -exu

set -o pipefail

if [[ "${DOWNLOAD_ROOT}" == gs://flatcar-jenkins-private/* ]]; then
  echo "Not supported"
  exit 1
else
  BASE_URL="https://storage.googleapis.com/$(echo $DOWNLOAD_ROOT | sed 's|gs://||g')/boards/${BOARD}/${FLATCAR_VERSION}"
fi

if [[ "${KOLA_TESTS}" == "" ]]; then
  KOLA_TESTS="*"
fi

SCRIPTFOLDER="$(dirname "$(readlink -f "$0")")"

# TODO: start tor in container on TOR_PORT

# Do not expand the kola test patterns globs
set -o noglob
timeout --signal=SIGQUIT 24h bin/kola run \
    --board=arm64-usr \
    --basename="${NAME}" \
    --parallel=1 \
    --platform=external \
    --external-user=core \
    --external-password="${EXTERNAL_PASSWORD}" \
    --external-provisioning-cmds="$(echo BASE_URL=${BASE_URL}; cat "${SCRIPTFOLDER}/external-provisioning-cmds")" \
    --external-serial-console-cmd="$(cat "${SCRIPTFOLDER}/external-serial-console-cmd")" \
    --external-deprovisioning-cmds="$(cat "${SCRIPTFOLDER}/external-deprovisioning-cmds")" \
    --external-socks="127.0.0.1:${TOR_PORT}" \
    --external-host="${EXTERNAL_HOST}" \
    --channel="${GROUP}" \
    --tapfile="${JOB_NAME##*/}.tap" \
    --torcx-manifest=torcx_manifest.json \
    ${KOLA_TESTS}
set +o noglob
