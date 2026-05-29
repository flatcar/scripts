#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#
# QoL wrapper around ci-automation test.sh for running Azure kola tests.
#
# Requirements:
# - Docker (for running the Mantle container).
# - Azure CLI login: az login
# - AZURE_SUBSCRIPTION_ID set if you have multiple subscriptions.
#
# Authentication:
#   Kola uses azidentity.DefaultAzureCredential which picks up Azure CLI
#   credentials automatically. Just run:
#     az login
#
#   If you have multiple subscriptions, set the one to use:
#     export AZURE_SUBSCRIPTION_ID="<your-subscription-id>"
#
# Prerequisites:
# - Azure VHD image in __build__/images/images/<arch>-usr/latest/
#
#     ./run_azure_tests.sh [amd64|arm64] [parallel] [test patterns...]
#
# Optional:
# - Custom Mantle container image in sdk_container/.repo/manifests/mantle-container.
# - AZURE_LOCATION (default: westus2)
# - AZURE_amd64_MACHINE_SIZE / AZURE_arm64_MACHINE_SIZE
# - MAX_RUNS to control retry count (default: 1)
#
# Output:
# - results-azure.md, results-azure.tap
# - results-azure-detailed.md, results-azure-detailed.tap
# - Detailed test output below __TESTS__/azure/

function set_azure_vars() {
  local arch="${1}"
  local parallel="${2}"

  PACKAGE_SOURCE_MODE="${PACKAGE_SOURCE_MODE:-PORTAGE}"
  local img_name="flatcar_production_azure_image"
  if [[ "${PACKAGE_SOURCE_MODE}" == "RPM" ]]; then
    img_name="acl_production_azure_test_image"
  fi

  local azure_image="/work/__build__/images/images/${arch}-usr/latest/${img_name}.vhd"

  # Verify az login session is active
  if ! az account show &>/dev/null; then
    echo "Error: Not logged into Azure. Please run: az login" >&2
    return 1
  fi

  # Resolve subscription: auto-detect if not set, require UUID if set
  if [[ -z "${AZURE_SUBSCRIPTION_ID:-}" ]]; then
    local sub_count
    sub_count="$(az account list --query 'length([])' -o tsv 2>/dev/null)"
    if [[ "${sub_count}" -gt 1 ]]; then
      echo "Error: Multiple Azure subscriptions found. Set AZURE_SUBSCRIPTION_ID (UUID)." >&2
      az account list --query '[].{name:name, id:id, isDefault:isDefault}' -o table >&2
      return 1
    fi
    AZURE_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
  elif ! [[ "${AZURE_SUBSCRIPTION_ID}" =~ ^[0-9a-f-]{36}$ ]]; then
    echo "Error: AZURE_SUBSCRIPTION_ID must be a UUID, not a name: '${AZURE_SUBSCRIPTION_ID}'" >&2
    echo "Find your subscription ID with: az account list --query '[].{name:name, id:id}' -o table" >&2
    return 1
  fi

  # Get tenant ID for EnvironmentCredential
  local tenant_id
  tenant_id="$(az account show --subscription "${AZURE_SUBSCRIPTION_ID}" --query tenantId -o tsv)"

  # The Docker container (test.sh) only mounts $PWD as /work.
  # Copy ~/.azure into the workspace so DefaultAzureCredential can find
  # the CLI tokens inside the container via AZURE_CONFIG_DIR.
  local azure_config_copy=".azure-config"
  rm -rf "${azure_config_copy}"
  cp -r "${HOME}/.azure" "${azure_config_copy}"

  # Credentials and config read by the mantle container via sdk_container/.env.
  # DefaultAzureCredential in kola tries multiple auth methods in order.
  # We set AZURE_CONFIG_DIR so AzureCLICredential can find the token cache,
  # and also set AZURE_TENANT_ID + AZURE_SUBSCRIPTION_ID for kola's own use.
  cat > sdk_container/.env <<EOF
export AZURE_IMAGE_NAME=${azure_image@Q}
export PARALLEL_TESTS=${parallel@Q}
export AZURE_LOCATION=${AZURE_LOCATION:-westus2}
export AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID@Q}
export AZURE_TENANT_ID=${tenant_id@Q}
export AZURE_CONFIG_DIR=/work/${azure_config_copy}
export AZURE_VNET_SUBNET_NAME=${AZURE_VNET_SUBNET_NAME:-}
export AZURE_USE_PRIVATE_IPS=${AZURE_USE_PRIVATE_IPS:-}
export PACKAGE_SOURCE_MODE=${PACKAGE_SOURCE_MODE@Q}
export KOLA_DEBUG=${KOLA_DEBUG:-}
${AZURE_TOKEN_CREDENTIALS:+export AZURE_TOKEN_CREDENTIALS="${AZURE_TOKEN_CREDENTIALS}"}
${AZURE_amd64_MACHINE_SIZE:+export AZURE_amd64_MACHINE_SIZE="${AZURE_amd64_MACHINE_SIZE}"}
${AZURE_arm64_MACHINE_SIZE:+export AZURE_arm64_MACHINE_SIZE="${AZURE_arm64_MACHINE_SIZE}"}
${AZURE_KOLA_VNET:+export AZURE_KOLA_VNET="${AZURE_KOLA_VNET}"}
${AZURE_USE_GALLERY:+export AZURE_USE_GALLERY="${AZURE_USE_GALLERY}"}
${AZURE_RESOURCE_GROUP_TAG:+export AZURE_RESOURCE_GROUP_TAG="${AZURE_RESOURCE_GROUP_TAG}"}
${AZURE_DISK_URI:+export AZURE_DISK_URI=${AZURE_DISK_URI@Q}}
${KOLA_TRUSTED_SOURCE_CIDR:+export KOLA_TRUSTED_SOURCE_CIDR=${KOLA_TRUSTED_SOURCE_CIDR@Q}}
EOF

  # Clean up copied azure config on exit
  echo "rm -rf '${azure_config_copy}'" >> ./ci-cleanup.sh

  export MAX_RETRIES=${MAX_RUNS:-1}
  export SKIP_COPY_TO_BINCACHE=1
}
#--

function run_azure_tests() (
  local arch="${1:-amd64}"
  if [[ $# -gt 0 ]] ; then shift; fi
  local parallel="${1:-4}"
  if [[ $# -gt 0 ]] ; then shift; fi

  rm -f results.*

  local mantle_container
  mantle_container="$(cat "sdk_container/.repo/manifests/mantle-container")"

  local tests=""
  if [[ $# -eq 0 ]] ; then
    # List all azure-platform tests, excluding devcontainer, using top-level globs
    tests="$(docker run "${mantle_container}" \
              kola list --platform azure --board="${arch}-usr" \
              | awk '!/^(devcontainer|Test)/ {if ($1 != "") print gensub(/^([^.]+).*/,"\\1",1,$1) ".*"}' | uniq)"
  else
    tests="${*}"
  fi

  source ci-automation/test.sh || exit 1
  set_azure_vars "${arch}" "${parallel}"

  echo "================================="
  echo "Using Mantle docker image '${mantle_container}'"
  echo "Architecture: ${arch}"
  echo "Azure location: ${AZURE_LOCATION:-westus2}"
  echo "================================="

  rm -f results.sqlite
  if [[ -n "${tests}" ]] ; then
    echo "Running azure tests"
    test_run "${arch}" azure ${tests}
  else
    echo "No tests to run."
    return 1
  fi
)
# --

if [[ "$(basename "${0}")" = "run_azure_tests.sh" ]] ; then
  set -euo pipefail
  run_azure_tests "${@}"
fi
