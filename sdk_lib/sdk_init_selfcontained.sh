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

# Nothing mounted on /mnt/host in self-contained mode
sudo chown -R sdk:sdk /home/sdk /mnt/host/source

version="$(source /mnt/host/source/.repo/manifests/version.txt; echo $FLATCAR_VERSION)"

rmdir /mnt/host/source/src/third_party
ln -s /mnt/host/source/src/scripts/sdk_container/src/third_party /mnt/host/source/src/

clone_version scripts /home/sdk/trunk/src/scripts "$version"
