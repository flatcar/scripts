#!/bin/bash

# Copyright (c) 2024-2025 The Flatcar Maintainers.
# Use of this source code is governed by the Apache 2.0 license.

# Script to publish Flatcar images to Azure Shared Gallery Images.

# Developer-visible flags.
DEFINE_string AZURE_SUBSCRIPTION_ID "d38033ba-ec21-470c-96cf-4c6db9658d8b" \
  "The subscription id to be used in Azure"
DEFINE_string AZURE_TENANT_ID "f41c056a-c993-42d0-8d91-57f0ff222694" \
  "The tenant ID to be used in Azure"
DEFINE_string IMAGE_PUBLISHER_NAME "flatcar" \
  "The name of the image publisher for Azure"
DEFINE_string IMAGE_PUBLISHER_URI "https://www.flatcar.org/" \
  "The URI of the image publisher for Azure"
DEFINE_string IMAGE_PUBLISHER_CONTACT "infra@flatcar-linux.org" \
  "The contact email of the image publisher"
DEFINE_string IMAGE_EULA_URL "https://www.flatcar.org/license" \
  "The EULA URL for the image in Azure"
DEFINE_string VHD_STORAGE_ACCOUNT_NAME "flatcar" \
  "The name of the storage account used to publish VHDs"
DEFINE_string AZURE_LOCATION "westeurope" \
  "The Azure region where the resources will be deployed"
DEFINE_string PUBLISHING_SIG_RESOURCE_GROUP "sayan-flatcar-image-gallery-publishing" \
  "The resource group for the publishing Shared Image Gallery"
DEFINE_string STAGING_SIG_RESOURCE_GROUP "sayan-flatcar-image-gallery-staging" \
  "The resource group for the staging Shared Image Gallery"
DEFINE_string FLATCAR_STAGING_GALLERY_NAME "sayan_flatcar_staging" \
  "The name of the staging Shared Image Gallery"
DEFINE_string FLATCAR_GALLERY_NAME "sayan_flatcar" \
  "The name of the production Shared Image Gallery"
DEFINE_string FLATCAR_VERSION "3374.2.1" \
  "The version of Flatcar to publish"
DEFINE_string FLATCAR_CHANNEL "stable" \
  "The Flatcar channel (e.g., stable, beta, alpha)"
DEFINE_string FLATCAR_ARCH "amd64" \
  "The architecture of the Flatcar image"
DEFINE_string FLATCAR_IMAGE_NAME "flatcar-${FLATCAR_CHANNEL}-${FLATCAR_ARCH}" \
  "The name of the Flatcar image to be used"
DEFINE_string FLATCAR_IMAGE_OFFER "${FLATCAR_CHANNEL}" \
  "The offer name for the Flatcar image"
DEFINE_string FLATCAR_IMAGE_SKU "${FLATCAR_IMAGE_NAME}" \
  "The SKU for the Flatcar image"
DEFINE_string VHD_STORAGE_SUBSCRIPTION_ID "${AZURE_SUBSCRIPTION_ID}" \
  "The subscription ID used for VHD storage"
DEFINE_string VHD_STORAGE_RESOURCE_GROUP_NAME "flatcar" \
  "The resource group name used for VHD storage"
DEFINE_string VHD_STORAGE_CONTAINER_NAME "publish" \
  "The name of the Azure Blob container where VHDs are stored"
DEFINE_string FLATCAR_COMMUNITY_GALLERY_PUBLIC_NAME_PREFIX "flatcar" \
  "The prefix for the Flatcar community gallery names"
DEFINE_string BLACKLISTED_TARGET_REGIONS "polandcentral australiacentral2 brazilsoutheast centraluseuap eastus2euap eastusstg francesouth germanynorth jioindiacentral norwaywest southafricawest switzerlandwest uaecentral brazilus southcentralusstg" \
  "Azure regions that are blacklisted from default image publishing"

DEFAULT_TARGET_REGIONS=$(az account list-locations -o json | jq -r '.[] | select( .metadata.regionType != "Logical" ) | .name' | sort | grep -v -E "(${BLACKLISTED_TARGET_REGIONS// /|})" | tr \\n ' ')
DEFINE_string TARGET_REGIONS "${DEFAULT_TARGET_REGIONS}" \
  "Target Azure regions for image publishing"

FLAGS_HELP="USAGE: publish_azure_sig [flags]
This script is primarily used for publishing images to Azure Shared Image
Galleries (SIG)
"
show_help_if_requested "$@"

# Parse command line
FLAGS "$@" || exit 1

eval set -- "${FLAGS_ARGV}"

# Only now can we die on error.  shflags functions leak non-zero error codes,
# so will die prematurely if 'switch_to_strict_mode' is specified before now.
switch_to_strict_mode -uo pipefail

function publish-flatcar-image() {
  ensure-flatcar-staging-sig-image-version-from-vhd

  IMAGE_NAME="${FLATCAR_IMAGE_NAME}"
  IMAGE_VERSION="${FLATCAR_VERSION}"
  GALLERY_NAME="${FLATCAR_GALLERY_NAME}"
  RESOURCE_GROUP_NAME="${PUBLISHING_SIG_RESOURCE_GROUP}"

  # shellcheck disable=SC2310 # This might return 1.
  if sig-image-version-exists; then
    return
  fi

  ensure-resource-group

  PUBLIC_NAME_PREFIX="${FLATCAR_COMMUNITY_GALLERY_PUBLIC_NAME_PREFIX}" ensure-community-sig

  IMAGE_OFFER="${FLATCAR_IMAGE_OFFER}" IMAGE_PUBLISHER="${IMAGE_PUBLISHER_NAME}" ensure-image-definition

  SOURCE_VERSION="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${STAGING_SIG_RESOURCE_GROUP}"
  SOURCE_VERSION="${SOURCE_VERSION}/providers/Microsoft.Compute/galleries"
  SOURCE_VERSION="${SOURCE_VERSION}/${FLATCAR_STAGING_GALLERY_NAME}/images/${IMAGE_NAME}/versions/${IMAGE_VERSION}"

  copy-sig-image-version
}

function ensure-flatcar-staging-sig-image-version-from-vhd() {
  IMAGE_NAME="${FLATCAR_IMAGE_NAME}"
  IMAGE_VERSION="${FLATCAR_VERSION}"
  GALLERY_NAME="${FLATCAR_STAGING_GALLERY_NAME}"
  RESOURCE_GROUP_NAME="${STAGING_SIG_RESOURCE_GROUP}"

  # shellcheck disable=SC2310 # This might return 1.
  if sig-image-version-exists; then
    return
  fi

  ensure-resource-group
  ensure-sig

  IMAGE_OFFER="${FLATCAR_IMAGE_OFFER}" IMAGE_PUBLISHER="${IMAGE_PUBLISHER_NAME}" ensure-image-definition

  STORAGE_ACCOUNT_ID="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${VHD_STORAGE_RESOURCE_GROUP_NAME}"
  STORAGE_ACCOUNT_ID="${STORAGE_ACCOUNT_ID}/providers/Microsoft.Storage/storageAccounts/${VHD_STORAGE_ACCOUNT_NAME}"

  VHD_URI="https://${VHD_STORAGE_ACCOUNT_NAME}.blob.core.windows.net/${VHD_STORAGE_CONTAINER_NAME}"
  VHD_URI="${VHD_URI}/flatcar-linux-${IMAGE_VERSION}-${FLATCAR_CHANNEL}-${FLATCAR_ARCH}.vhd"

  az sig image-version create \
    --resource-group "${RESOURCE_GROUP_NAME}" \
    --gallery-name "${GALLERY_NAME}" \
    --gallery-image-definition "${IMAGE_NAME}" \
    --gallery-image-version "${IMAGE_VERSION}" \
    --os-vhd-storage-account "${STORAGE_ACCOUNT_ID}" \
    --os-vhd-uri "${VHD_URI}"
}

function copy-sig-image-version() {
  IMAGE_NAME=${IMAGE_NAME:-}
  IMAGE_VERSION="${IMAGE_VERSION:-}"
  GALLERY_NAME=${GALLERY_NAME:-}
  RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:-}
  EXCLUDE_FROM_LATEST=${EXCLUDE_FROM_LATEST:-false}
  SOURCE_VERSION="${SOURCE_VERSION:-}"

  # shellcheck disable=SC2086 # Apparently target regions must be space-separated for Azure CLI.
  az sig image-version create \
    --gallery-image-definition "${IMAGE_NAME}" \
    --gallery-image-version "${IMAGE_VERSION}" \
    --gallery-name "${GALLERY_NAME}" \
    --resource-group "${RESOURCE_GROUP_NAME}" \
    --exclude-from-latest "${EXCLUDE_FROM_LATEST}" \
    --image-version "${SOURCE_VERSION}" \
    --target-regions ${TARGET_REGIONS}
}

function sig-image-version-exists() {
  IMAGE_NAME=${IMAGE_NAME:-}
  IMAGE_VERSION="${IMAGE_VERSION:-}"
  GALLERY_NAME=${GALLERY_NAME:-}
  RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:-}

  if ! az sig image-version show \
    --gallery-image-definition "${IMAGE_NAME}" \
    --gallery-image-version "${IMAGE_VERSION}" \
    --gallery-name "${GALLERY_NAME}" \
    --resource-group "${RESOURCE_GROUP_NAME}" \
    --output none \
    --only-show-errors; then
      echo "SIG image ${RESOURCE_GROUP_NAME}/${GALLERY_NAME}/${IMAGE_VERSION}/${IMAGE_NAME} does not exist"

    return 1
  fi

  echo "SIG image ${RESOURCE_GROUP_NAME}/${GALLERY_NAME}/${IMAGE_VERSION}/${IMAGE_NAME} already exists"

  return 0
}

function ensure-image-definition() {
  IMAGE_NAME=${IMAGE_NAME:-}
  GALLERY_NAME=${GALLERY_NAME:-}
  IMAGE_OFFER=${IMAGE_OFFER:-}
  IMAGE_PUBLISHER=${IMAGE_PUBLISHER:-}
  RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:-}

  local architecture

  case "${FLATCAR_ARCH}" in
    amd64)
      architecture=x64
      ;;
    arm64)
      architecture=Arm64
      ;;
    *)
      echo "Unsupported architecture: '${FLATCAR_ARCH}'"
      exit 1
      ;;
  esac

  az sig image-definition create \
    --gallery-image-definition "${IMAGE_NAME}" \
    --gallery-name "${GALLERY_NAME}" \
    --offer "${IMAGE_OFFER}" \
    --os-type Linux \
    --publisher "${IMAGE_PUBLISHER}" \
    --resource-group "${RESOURCE_GROUP_NAME}" \
    --sku "${IMAGE_NAME}" \
    --architecture "${architecture}" \
    --hyper-v-generation V2
}

function ensure-sig() {
  GALLERY_NAME=${GALLERY_NAME:-}
  RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:-}

  az sig create \
    --gallery-name "${GALLERY_NAME}" \
    --resource-group "${RESOURCE_GROUP_NAME}"
}

function ensure-community-sig() {
  GALLERY_NAME=${GALLERY_NAME:-}
  RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:-}
  PUBLIC_NAME_PREFIX=${PUBLIC_NAME_PREFIX:-}

  az sig create \
    --gallery-name "${GALLERY_NAME}" \
    --resource-group "${RESOURCE_GROUP_NAME}" \
    --eula "${IMAGE_EULA_URL}" \
    --location "${AZURE_LOCATION}" \
    --public-name-prefix "${PUBLIC_NAME_PREFIX}"
}

function ensure-resource-group() {
  RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:-}

  if ! az group show -n "${RESOURCE_GROUP_NAME}" -o none 2>/dev/null; then
    az group create -n "${RESOURCE_GROUP_NAME}" -l "${AZURE_LOCATION}"
  fi
}

ensure-flatcar-staging-sig-image-version-from-vhd
publish-flatcar-image
