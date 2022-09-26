#!/bin/bash
set -euo pipefail
timeout --signal=SIGQUIT 60m ore aws gc --access-id "${AWS_ACCESS_KEY_ID}" --secret-key "${AWS_SECRET_ACCESS_KEY}"
timeout --signal=SIGQUIT 60m ore do gc --config-file=<(echo "${DIGITALOCEAN_TOKEN_JSON}" | base64 --decode)
timeout --signal=SIGQUIT 60m ore gcloud gc --json-key <(echo "${GCP_JSON_KEY}" | base64 --decode)
# Because the Azure file gets read multiple times it can't be passed like <(cmd) because bash backs this FD
# by a pipe meaning the data is gone after reading. We can create an FD (the FD number is assigned to
# variable through exec {NAME}) manually and use a file under /tmp to back it instead, allowing multiple
# reads.
echo "${AZURE_PROFILE}" | base64 --decode > /tmp/azure_profile
exec {azure_profile}</tmp/azure_profile
rm /tmp/azure_profile
echo "${AZURE_AUTH_CREDENTIALS}" | base64 --decode > /tmp/azure_auth
exec {azure_auth}</tmp/azure_auth
rm /tmp/azure_auth
timeout --signal=SIGQUIT 60m ore azure gc --duration 6h \
  --azure-profile="/proc/$$/fd/${azure_profile}" --azure-auth="/proc/$$/fd/${azure_auth}"
timeout --signal=SIGQUIT 60m ore equinixmetal gc --duration 6h \
  --project="${EQUINIXMETAL_PROJECT}" --gs-json-key=<(echo "${GCP_JSON_KEY}" | base64 --decode) --api-key="${EQUINIXMETAL_KEY}"
