#!/bin/bash

# Copyright (c) 2025 The Flatcar Maintainers.
# Use of this source code is governed by the Apache 2.0 license.

function release_azure_marketplace() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _release_azure_marketplace_impl "${@}"
    )
}

secret_from_base64() {
    local key="$1"
    local base64_string="$2"

    # Decode base64 and extract the value using jq
    echo "$base64_string" | base64 -d | jq -r ".$key"
}

function _release_azure_marketplace_impl() {
  source sdk_lib/sdk_container_common.sh
  source ci-automation/ci_automation_common.sh
  source ci-automation/gpg_setup.sh

  source sdk_container/.repo/manifests/version.txt

  # todo: update the vernum and the channel values.
  # they are currently hardcoded to test.
  local vernum="4459.2.4"
  local channel=
  channel="stable"
  local docker_vernum=""
  docker_vernum="$(vernum_to_docker_image_version "${vernum}")"
  local container_name="az-marketplace-publish-${docker_vernum}"

  # A job on each worker prunes old mantle images (docker image prune), no need to do it here
  echo "docker rm -f '${container_name}'" >> ./ci-cleanup.sh

  source sdk_container/.env
  AZ_STORAGE_KEY=$(secret_from_base64 "AZ_STORAGE_KEY" "${AZ_MARKETPLACE_PUBLISH}")
  AZ_TENANT_ID=$(secret_from_base64 "AZ_TENANT_ID" "${AZ_MARKETPLACE_PUBLISH}")
  AZ_CLIENT_ID=$(secret_from_base64 "AZ_CLIENT_ID" "${AZ_MARKETPLACE_PUBLISH}")
  AZ_SECRET_VALUE=$(secret_from_base64 "AZ_SECRET_VALUE" "${AZ_MARKETPLACE_PUBLISH}")

  docker run --pull always --rm --name="${container_name}" --net host \
    -e AZ_STORAGE_KEY="${AZ_STORAGE_KEY}" \
    -e AZ_TENANT_ID="${AZ_TENANT_ID}" \
    -e AZ_CLIENT_ID="${AZ_CLIENT_ID}" \
    -e AZ_SECRET_VALUE="${AZ_SECRET_VALUE}" \
    -v "${PWD}"/ci-automation/release/azure_marketplace_publish.py:/app/azure_marketplace_publish.py \
    -w /app \
    ghcr.io/astral-sh/uv:alpine \
    uv run azure_marketplace_publish.py \
      -p "${channel}" \
      -v "${vernum}"
}
