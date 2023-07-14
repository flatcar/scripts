#!/bin/bash

set -euo pipefail

[[ -n ${DEBUG:-} ]] && set -o xtrace

# Flatcar environment specific variables.
AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-d38033ba-ec21-470c-96cf-4c6db9658d8b}
AZURE_TENANT_ID=${AZURE_TENANT_ID:-f41c056a-c993-42d0-8d91-57f0ff222694}
IMAGE_PUBLISHER_NAME=${IMAGE_PUBLISHER_NAME:-flatcar}
IMAGE_PUBLISHER_URI=${IMAGE_PUBLISHER_URI:-https://www.flatcar.org/}
IMAGE_PUBLISHER_CONTACT=${IMAGE_PUBLISHER_CONTACT:-infra@flatcar-linux.org}
IMAGE_EULA_URL=${IMAGE_EULA_URL:-https://kinvolk.io/legal/open-source/}
VHD_STORAGE_ACCOUNT_NAME=${VHD_STORAGE_ACCOUNT_NAME:-flatcar}

# Generic Flatcar variables.
AZURE_LOCATION=${AZURE_LOCATION:-westeurope}
PUBLISHING_SIG_RESOURCE_GROUP=${PUBLISHING_SIG_RESOURCE_GROUP:-flatcar-image-gallery-publishing}
STAGING_SIG_RESOURCE_GROUP=${STAGING_SIG_RESOURCE_GROUP:-flatcar-image-gallery-staging}
FLATCAR_STAGING_GALLERY_NAME=${FLATCAR_STAGING_GALLERY_NAME:-flatcar_staging}
FLATCAR_GALLERY_NAME=${FLATCAR_GALLERY_NAME:-flatcar}
FLATCAR_VERSION=${FLATCAR_VERSION:-3374.2.1}
FLATCAR_CHANNEL=${FLATCAR_CHANNEL:-stable}
FLATCAR_ARCH=${FLATCAR_ARCH:-amd64}
FLATCAR_IMAGE_NAME=${FLATCAR_IMAGE_NAME:-flatcar-${FLATCAR_CHANNEL}-${FLATCAR_ARCH}}
FLATCAR_IMAGE_OFFER=${FLATCAR_IMAGE_OFFER:-${FLATCAR_CHANNEL}}
FLATCAR_IMAGE_SKU=${FLATCAR_IMAGE_SKU:-${FLATCAR_IMAGE_NAME}}
VHD_STORAGE_SUBSCRIPTION_ID=${VHD_STORAGE_SUBSCRIPTION_ID:-${AZURE_SUBSCRIPTION_ID}}
VHD_STORAGE_RESOURCE_GROUP_NAME=${VHD_STORAGE_RESOURCE_GROUP_NAME:-flatcar}
VHD_STORAGE_CONTAINER_NAME=${VHD_STORAGE_CONTAINER_NAME:-publish}
FLATCAR_COMMUNITY_GALLERY_PUBLIC_NAME_PREFIX=${FLATCAR_COMMUNITY_GALLERY_PUBLIC_NAME_PREFIX:-flatcar}

# Regions below require explicit opt-in, so let's initially skip them from "default" regions until they are requested.
BLACKLISTED_TARGET_REGIONS=${BLACKLISTED_TARGET_REGIONS:-polandcentral australiacentral2 brazilsoutheast centraluseuap eastus2euap eastusstg francesouth germanynorth jioindiacentral norwaywest southafricawest switzerlandwest uaecentral brazilus southcentralusstg}
DEFAULT_TARGET_REGIONS=$(az account list-locations -o json | jq -r '.[] | select( .metadata.regionType != "Logical" ) | .name' | sort | grep -v -E "(${BLACKLISTED_TARGET_REGIONS// /|})" | tr \\n ' ')
TARGET_REGIONS=${TARGET_REGIONS:-${DEFAULT_TARGET_REGIONS}}

# CAPI specific variables.
KUBERNETES_SEMVER=${KUBERNETES_SEMVER:-v1.23.13}
FLATCAR_CAPI_GALLERY_NAME=${FLATCAR_CAPI_GALLERY_NAME:-flatcar4capi}
FLATCAR_CAPI_STAGING_GALLERY_NAME=${FLATCAR_CAPI_STAGING_GALLERY_NAME:-flatcar4capi_staging}
FLATCAR_CAPI_IMAGE_NAME=${FLATCAR_CAPI_IMAGE_NAME:-${FLATCAR_IMAGE_NAME}-capi-${KUBERNETES_SEMVER}}
FLATCAR_CAPI_IMAGE_OFFER=${FLATCAR_CAPI_IMAGE_OFFER:-${FLATCAR_CHANNEL}-capi}
FLATCAR_CAPI_IMAGE_SKU=${FLATCAR_CAPI_IMAGE_SKU:-${FLATCAR_CAPI_IMAGE_NAME}}
FLATCAR_CAPI_COMMUNITY_GALLERY_PUBLIC_NAME_PREFIX=${FLATCAR_CAPI_COMMUNITY_GALLERY_PUBLIC_NAME_PREFIX:-flatcar4capi}
IMAGE_BUILDER_GIT_REMOTE="${IMAGE_BUILDER_GIT_REMOTE:-https://github.com/kubernetes-sigs/image-builder.git}"
IMAGE_BUILDER_GIT_REPOSITORY_PATH="${IMAGE_BUILDER_GIT_REPOSITORY_PATH:-/tmp/image-builder}"
IMAGE_BUILDER_GIT_VERSION="${IMAGE_BUILDER_GIT_VERSION:-main}"

function azure_login() {
  az login --service-principal -u "${AZURE_CLIENT_ID}" -p "${AZURE_CLIENT_SECRET}" --tenant "${AZURE_TENANT_ID}"
  az account set -s "${AZURE_SUBSCRIPTION_ID}"
}

function publish-flatcar-capi-image() {
  require-amd64-arch

  # First, make sure staging image is available before publishing.
  build-capi-staging-image

  azure_login

  IMAGE_NAME="${FLATCAR_CAPI_IMAGE_NAME}"
  IMAGE_VERSION="${FLATCAR_VERSION}"
  GALLERY_NAME="${FLATCAR_CAPI_GALLERY_NAME}"
  RESOURCE_GROUP_NAME="${PUBLISHING_SIG_RESOURCE_GROUP}"

  ensure-resource-group
  ensure-community-sig

  IMAGE_OFFER="${FLATCAR_CAPI_IMAGE_OFFER}"
  IMAGE_PUBLISHER="${IMAGE_PUBLISHER_NAME}"
  ensure-image-definition

  SOURCE_VERSION="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${STAGING_SIG_RESOURCE_GROUP}"
  SOURCE_VERSION="${SOURCE_VERSION}/providers/Microsoft.Compute/galleries"
  SOURCE_VERSION="${SOURCE_VERSION}/${FLATCAR_CAPI_STAGING_GALLERY_NAME}/images/${IMAGE_NAME}/versions/${IMAGE_VERSION}"

  EXCLUDE_FROM_LATEST=true copy-sig-image-version
}

function build-capi-staging-image() {
  require-amd64-arch

  # First, make sure that base Flatcar image is available.
  ensure-flatcar-staging-sig-image-version-from-vhd

  azure_login

  IMAGE_NAME="${FLATCAR_CAPI_IMAGE_NAME}"
  IMAGE_VERSION="${FLATCAR_VERSION}"
  GALLERY_NAME="${FLATCAR_CAPI_STAGING_GALLERY_NAME}"
  RESOURCE_GROUP_NAME="${STAGING_SIG_RESOURCE_GROUP}"

  ensure-resource-group
  ensure-sig

  IMAGE_OFFER="${FLATCAR_CAPI_IMAGE_OFFER}"
  IMAGE_PUBLISHER="${IMAGE_PUBLISHER_NAME}"
  ensure-image-definition

  if [[ ! -d "${IMAGE_BUILDER_GIT_REPOSITORY_PATH}" ]]; then
    git clone "${IMAGE_BUILDER_GIT_REMOTE}" "${IMAGE_BUILDER_GIT_REPOSITORY_PATH}"
  fi

  pushd "${IMAGE_BUILDER_GIT_REPOSITORY_PATH}/images/capi" || exit 1

  git checkout "${IMAGE_BUILDER_GIT_VERSION}"

  cat <<EOF > packer.json
{
  "sig_image_version": "${FLATCAR_VERSION}",
  "kubernetes_semver": "${KUBERNETES_SEMVER}",
  "image_name": "${IMAGE_NAME}",
  "image_offer": "",
  "image_publisher": "",
  "image_sku": "",
  "image_version": "",
  "plan_image_offer": "",
  "plan_image_publisher": "",
  "plan_image_sku": "",
  "source_sig_subscription_id": "${AZURE_SUBSCRIPTION_ID}",
  "source_sig_resource_group_name": "${STAGING_SIG_RESOURCE_GROUP}",
  "source_sig_name": "${FLATCAR_STAGING_GALLERY_NAME}",
  "source_sig_image_name": "${FLATCAR_IMAGE_NAME}",
  "source_sig_image_version": "${FLATCAR_VERSION}"
}
EOF

  export RESOURCE_GROUP_NAME="${STAGING_SIG_RESOURCE_GROUP}"
  export GALLERY_NAME="${FLATCAR_CAPI_STAGING_GALLERY_NAME}"
  export AZURE_SUBSCRIPTION_ID
  export AZURE_LOCATION
  export AZURE_CLIENT_ID
  export AZURE_CLIENT_SECRET
  export PACKER_VAR_FILES=packer.json

  # I'd recommend running in debug mode when running interactively, as Packer tends to produce hard to debug
  # error messages.
  export DEBUG=true
  export PACKER_LOG=1

  make build-azure-sig-flatcar-gen2 FLATCAR_VERSION="${FLATCAR_VERSION}"

  popd || exit 1
}

function publish-flatcar-image() {
  ensure-flatcar-staging-sig-image-version-from-vhd

  azure_login

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

  IMAGE_OFFER="${FLATCAR_IMAGE_OFFER}" \
    IMAGE_PUBLISHER="${IMAGE_PUBLISHER_NAME}" \
    ensure-image-definition

  SOURCE_VERSION="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${STAGING_SIG_RESOURCE_GROUP}"
  SOURCE_VERSION="${SOURCE_VERSION}/providers/Microsoft.Compute/galleries"
  SOURCE_VERSION="${SOURCE_VERSION}/${FLATCAR_STAGING_GALLERY_NAME}/images/${IMAGE_NAME}/versions/${IMAGE_VERSION}"

  copy-sig-image-version
}

function ensure-flatcar-staging-sig-image-version-from-vhd() {
  azure_login

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

# Below are utility functions.
function require-amd64-arch() {
  if [[ "${FLATCAR_ARCH}" != "amd64" ]]; then
    echo "Unsupported architecture '${FLATCAR_ARCH}'. Only supported is 'amd64'."
    exit 1
  fi
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

if [[ $# -eq 0 ]]; then
  cat << EOF
usage: $0 <action>

Available actions:
  - ensure-flatcar-staging-sig-image-version-from-vhd - Creates Flatcar image in staging SIG from VHD image.
  - publish-flatcar-image - Publishes Flatcar image to community SIG from staging SIG.
  - build-capi-staging-image - Builds Flatcar CAPI image using image-builder to staging SIG.
  - publish-flatcar-capi-image - Publishes Flatcar CAPI image to community SIG from staging SIG.
EOF

  exit 0
fi

$1
