#!/bin/bash

set -euo pipefail

curl -L -o cork https://github.com/flatcar-linux/mantle/releases/download/v"${CORK_VERSION}"/cork-"${CORK_VERSION}"-amd64
curl -L -o cork.sig https://github.com/flatcar-linux/mantle/releases/download/v"${CORK_VERSION}"/cork-"${CORK_VERSION}"-amd64.sig
gpg --keyserver keys.gnupg.net --receive-keys 84C8E771C0DF83DFBFCAAAF03ADA89DEC2507883
gpg --verify cork.sig cork
rm -f cork.sig
chmod +x cork
mkdir -p ~/.local/bin
mv cork ~/.local/bin

export PATH=$PATH:$HOME/.local/bin
mkdir -p ~/flatcar-sdk

pushd ~/flatcar-sdk || exit
cork create || true

# /var under the chroot has to be writable by the runner user
sudo chown -R runner:docker ~/flatcar-sdk/chroot/var

git -C src/third_party/coreos-overlay reset --hard github/flatcar-master
git -C src/third_party/coreos-overlay config user.name 'Flatcar Buildbot'
git -C src/third_party/coreos-overlay config user.email 'buildbot@flatcar-linux.org'
popd || exit

echo ::set-output name=path::"${PATH}"
