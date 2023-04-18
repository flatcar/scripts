#!/bin/bash

# This script will mirror the list of Calico images
# from Docker Hub to GHCR.

# tag will hold the version of calico images we
# previously fetched
tag="${1}"

# list of images to mirror from Docker Hub
images=(
  calico/typha
  calico/pod2daemon-flexvol
  calico/cni
  calico/node
  calico/kube-controllers
)

# we iterate over the images we want to mirror
for image in "${images[@]}"; do
  ./mirror-to-ghcr.sh "${image}" "${tag}"
done
