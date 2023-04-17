#!/bin/bash

echo "This script will initialise your Flatcar SDK container as a self-contained SDK."
echo "Please note that the preferred way of using the Flatcar SDK container is by cloning"
echo "   https://github.com/flatcar/scripts"
echo "and using the ./run_sdk_container script."

echo
echo "Press [RETURN] to continue, CTRL+C to abort"
echo

read junk
unset junk

# --

function clone_version() {
    local repo="$1"
    local dest="$2"
    local version="$3"

    git clone https://github.com/flatcar/$repo "$dest"
    git -C "${dest}" fetch --all
    local tag=$(git -C "${dest}" tag -l | grep "${version}")
    git -C "${dest}" checkout "$tag"
}
# --

version="$(source /mnt/host/source/.repo/manifests/version.txt; echo $FLATCAR_VERSION)"

mkdir -p /home/sdk/trunk/src/third_party/

clone_version scripts /home/sdk/trunk/src/scripts "$version"
