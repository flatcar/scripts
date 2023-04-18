#!/bin/bash

# This generic script aims to mirror an image from Docker hub to another registry.
# Authentication to the registry must be done before.

image="${1}"
imagetag="${2}"
org="${3:-kinvolk}"

# we want both arch for running tests
platforms=( amd64 arm64 )

# tags will hold the mirrored images
tags=()

name="ghcr.io/${org}/${image}:${imagetag}"

for platform in "${platforms[@]}"; do
  # we first fetch the image from Docker Hub
  var=$(docker pull "${image}:${imagetag}" --platform="linux/${platform}" -q)
  # we prepare the image to be pushed into another registry
  tag="${name}-${platform}"
  # we tag the image to create the mirrored image
  docker tag "${var}" "${tag}"
  docker push "${tag}"
  tags+=( "${tag}" )
done

docker manifest create "${name}" "${tags[@]}"
# some images have bad arch specs in the individual image manifests :(
docker manifest annotate "${name}" "${name}-arm64" --arch arm64
docker manifest push --purge "${name}"
