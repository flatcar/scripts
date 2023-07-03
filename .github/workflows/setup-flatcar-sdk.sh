#!/bin/bash

set -euo pipefail

if [[ -z "${WORK_SCRIPTS_DIR:-}" ]]; then
    echo 'WORK_SCRIPTS_DIR unset, should be pointing to the scripts repo which will be updated'
fi

sudo ln -sfn /bin/bash /bin/sh
sudo apt-get update
sudo apt-get install -y ca-certificates curl git gnupg lbzip2 lsb-release \
    qemu-user-static zstd
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

pushd "${WORK_SCRIPTS_DIR}"

source ci-automation/ci_automation_common.sh
source sdk_container/.repo/manifests/version.txt

# run_sdk_container requires a tag to exist in the repo it resides,
# which may not be the case for forked repos. Add some fake tag in
# this case.
if ! git describe --tags &>/dev/null; then
    git tag "${CHANNEL}-${FLATCAR_VERSION}"
fi

arch="amd64"
sdk_name="flatcar-sdk-${arch}"

if [[ "${CHANNEL}" = 'main' ]]; then
    # for main channel, pull in alpha SDK
    MIRROR_LINK='https://alpha.release.flatcar-linux.net/amd64-usr/current'
fi

# Pin the docker image version to that of the latest release in the channel.
docker_sdk_vernum="$(curl -s -S -f -L "${MIRROR_LINK}/version.txt" \
    | grep -m 1 FLATCAR_SDK_VERSION= | cut -d = -f 2- \
)"

docker_image_from_registry_or_buildcache "${sdk_name}" "${docker_sdk_vernum}"

sdk_full_name="$(docker_image_fullname "${sdk_name}" "${docker_sdk_vernum}")"

docker_vernum="$(vernum_to_docker_image_version "${FLATCAR_VERSION_ID}")"
packages_container_name="flatcar-packages-${arch}-${docker_vernum}"

popd

echo "PACKAGES_CONTAINER=${packages_container_name}" >>"${GITHUB_OUTPUT}"
echo "SDK_NAME=${sdk_full_name}" >>"${GITHUB_OUTPUT}"
