#!/bin/bash
set -ex

AZURE_CATEGORY_OPT=""
if [[ "${IS_NON_SPONSORED}" == true ]]
then
  AZURE_CATEGORY_OPT="--azure-category=pro"
fi

rm -f images.json

[ -s verify.asc ] && verify_key=--verify-key=verify.asc || verify_key=

bin/plume pre-release --force \
    --debug \
    --platform=azure \
    --azure-profile="${AZURE_CREDENTIALS}" \
    --azure-auth="${AZURE_AUTH_CREDENTIALS}" \
    --gce-json-key="${GOOGLE_APPLICATION_CREDENTIALS}" \
    --board="${BOARD}" \
    --channel="${CHANNEL}" \
    --version="${FLATCAR_VERSION}" \
    --write-image-list=images.json \
    ${AZURE_CATEGORY_OPT} \
    $verify_key

sas_url=$(jq -r '.azure.image' images.json)
if [ "${sas_url}" = "null" ]; then
  sas_url=""
fi
tee test.properties << EOF
SAS_URL ^ ${sas_url:?}
EOF
