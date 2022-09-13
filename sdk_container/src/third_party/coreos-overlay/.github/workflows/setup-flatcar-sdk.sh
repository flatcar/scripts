#!/bin/bash

set -euo pipefail

sudo ln -sfn /bin/bash /bin/sh
sudo apt-get install -y ca-certificates curl git gnupg lbzip2 lsb-release \
    qemu-user-static
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-compose-plugin

mkdir -p ~/flatcar-sdk
git -C ~/flatcar-sdk clone https://github.com/flatcar-linux/scripts

pushd ~/flatcar-sdk/scripts || exit

source ci-automation/ci_automation_common.sh
source sdk_container/.repo/manifests/version.txt

git submodule update --init --recursive

arch="amd64"
channel_version="alpha-${FLATCAR_VERSION_ID}"
check_version_string "${channel_version}"

export SDK_NAME="flatcar-sdk-${arch}"

# Pin the docker image version to that of the latest release.
docker_sdk_vernum="$(curl -s -S -f -L \
    https://alpha.release.flatcar-linux.net/amd64-usr/current/version.txt \
    | grep -m 1 FLATCAR_SDK_VERSION= | cut -d = -f 2- \
)"

docker_image_from_registry_or_buildcache "${SDK_NAME}" "${docker_sdk_vernum}"
export SDK_NAME="$(docker_image_fullname "${SDK_NAME}" "${docker_sdk_vernum}")"

vernum="${channel_version#*-}" # remove main-,alpha-,beta-,stable-,lts- version tag
docker_vernum="$(vernum_to_docker_image_version "${vernum}")"
export PACKAGES_CONTAINER="flatcar-packages-${arch}-${docker_vernum}"

popd || exit

echo ::set-output name=path::"${PATH}"
echo ::set-output name=PACKAGES_CONTAINER::"${PACKAGES_CONTAINER}"
echo ::set-output name=SDK_NAME::"${SDK_NAME}"
