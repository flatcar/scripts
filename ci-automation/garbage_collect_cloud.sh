#!/bin/bash
set -euo pipefail
timeout --signal=SIGQUIT 60m ore aws gc --access-id "${AWS_ACCESS_KEY_ID}" --secret-key "${AWS_SECRET_ACCESS_KEY}"
timeout --signal=SIGQUIT 60m ore do gc --config-file=<(echo "${DIGITALOCEAN_TOKEN_JSON}" | base64 --decode)
timeout --signal=SIGQUIT 60m ore gcloud gc --json-key <(echo "${GCP_JSON_KEY}" | base64 --decode)
timeout --signal=SIGQUIT 60m ore azure gc --duration 6h --azure-identity
timeout --signal=SIGQUIT 60m ore equinixmetal gc --duration 6h \
  --project="${EQUINIXMETAL_PROJECT}" --gs-json-key=<(echo "${GCP_JSON_KEY}" | base64 --decode) --api-key="${EQUINIXMETAL_KEY}"
timeout --signal=SIGQUIT 60m ore openstack gc --duration 6h \
  --config-file=<(echo "${OPENSTACK_CREDS}" | base64 --decode)
