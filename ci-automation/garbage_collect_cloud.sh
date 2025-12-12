#!/bin/bash
set -euo pipefail
source ci-automation/ci_automation_common.sh
timeout --signal=SIGQUIT 60m ore aws gc --access-id "${AWS_ACCESS_KEY_ID}" --secret-key "${AWS_SECRET_ACCESS_KEY}"
timeout --signal=SIGQUIT 60m ore do gc --config-file=<(echo "${DIGITALOCEAN_TOKEN_JSON}" | base64 --decode)
timeout --signal=SIGQUIT 60m ore gcloud gc --json-key <(echo "${GCP_JSON_KEY}" | base64 --decode)
timeout --signal=SIGQUIT 60m ore azure gc --duration 6h
timeout --signal=SIGQUIT 60m ore brightbox gc --duration 6h \
  --brightbox-client-id="${BRIGHTBOX_CLIENT_ID}" --brightbox-client-secret="${BRIGHTBOX_CLIENT_SECRET}"
timeout --signal=SIGQUIT 60m ore akamai gc --duration 6h \
  --akamai-token="${AKAMAI_TOKEN}"
timeout --signal=SIGQUIT 60m ore stackit gc --duration 6h \
  --stackit-service-account-key-path=<(echo "${STACKIT_SERVICE_ACCOUNT}" | base64 --decode) \
  --stackit-project-id="${STACKIT_PROJECT_ID}"
secret_to_file aws_credentials_config_file "${AWS_CREDENTIALS}"
for channel in alpha beta stable lts; do
  for arch in amd64 arm64; do
    timeout --signal=SIGQUIT 240m plume prune --days 365 \
      --keep-last 2 \
      --days-soft-deleted 21 \
      --check-last-launched \
      --days-last-launched 60 \
      --verbose \
      --board="${arch}-usr" \
      --channel="${channel}" \
      --aws-credentials="${aws_credentials_config_file}"
  done
done
