#!/bin/bash

set -ex

SCRIPTFOLDER="$(dirname "$(readlink -f "$0")")"
# strip $PWD prefix so that we can access the path relative to the container working directory
SCRIPTFOLDER=${SCRIPTFOLDER#$PWD/}

DOCKER_IMG=ghcr.io/kinvolk/kola-test-runner:latest

envarg=()
envflags=(
  SSH_AUTH_SOCK
  BOARD
  MANIFEST_URL
  SDK_URL_PATH
  CHANNEL_BASE
  GROUP
  KOLA_TESTS
  MANIFEST_TAG
  DOWNLOAD_ROOT
  PARALLEL
  GOOGLE_APPLICATION_CREDENTIALS
  NATIVE_ARM64
)
for envvar in ${envflags[@]}; do
  envarg+=( -e "${envvar}=${!envvar}" )
done

docker pull ${DOCKER_IMG}
exec docker run --privileged \
  --rm \
  -v /dev:/dev \
  -w /mnt/host/source \
  -v ${PWD}:/mnt/host/source \
  -v ${GOOGLE_APPLICATION_CREDENTIALS}:${GOOGLE_APPLICATION_CREDENTIALS} \
  ${SSH_AUTH_SOCK:+-v ${SSH_AUTH_SOCK}:${SSH_AUTH_SOCK}} \
  "${envarg[@]}" \
  ${DOCKER_IMG} \
  "${SCRIPTFOLDER}/qemu_common.sh" qemu_uefi
