#!/bin/bash
set -ex
case "${CHANNEL}" in
    stable|beta)
        boards=( amd64-usr )
        ;;
    *)
      	boards=( amd64-usr arm64-usr )
        ;;
esac

for board in "${boards[@]}"
do
        bin/plume release \
            --debug \
            --aws-credentials="${AWS_CREDENTIALS}" \
            --azure-profile="${AZURE_CREDENTIALS}" \
            --azure-auth="${AZURE_AUTH_CREDENTIALS}" \
            --gce-json-key="${GOOGLE_APPLICATION_CREDENTIALS}" \
            --gce-release-key="${GOOGLE_RELEASE_CREDENTIALS}" \
            --board="${board}" \
            --channel="${CHANNEL}" \
            --version="${VERSION}"
done
