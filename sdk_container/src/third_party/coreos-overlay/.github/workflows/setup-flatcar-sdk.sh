#!/bin/bash

set -euo pipefail

CORK_VERSION=$(curl -sL https://api.github.com/repos/kinvolk/mantle/releases/latest | jq -r .tag_name | sed -e 's/^v//')
curl -L -o cork https://github.com/kinvolk/mantle/releases/download/v"${CORK_VERSION}"/cork-"${CORK_VERSION}"-amd64
curl -L -o cork.sig https://github.com/kinvolk/mantle/releases/download/v"${CORK_VERSION}"/cork-"${CORK_VERSION}"-amd64.sig
curl -LO https://www.flatcar-linux.org/security/image-signing-key/Flatcar_Image_Signing_Key.asc
gpg --import Flatcar_Image_Signing_Key.asc
gpg --verify cork.sig cork
rm -f cork.sig Flatcar_Image_Signing_Key.asc
chmod +x cork
mkdir -p ~/.local/bin
mv cork ~/.local/bin

export PATH=$PATH:$HOME/.local/bin
mkdir -p ~/flatcar-sdk

pushd ~/flatcar-sdk || exit
cork create || true

sudo tee "./chroot/etc/portage/make.conf" <<EOF
PORTDIR="/mnt/host/source/src/third_party/portage-stable"
PORTDIR_OVERLAY="/mnt/host/source/src/third_party/coreos-overlay"
DISTDIR="/mnt/host/source/.cache/distfiles"
PKGDIR="/var/lib/portage/pkgs"
PORT_LOGDIR="/var/log/portage"
EOF

sudo tee "./chroot/etc/portage/repos.conf/coreos.conf" <<EOF
[DEFAULT]
main-repo = portage-stable

[gentoo]
disabled = true

[coreos]
location = /mnt/host/source/src/third_party/coreos-overlay

[portage-stable]
location = /mnt/host/source/src/third_party/portage-stable
EOF

# /var under the chroot has to be writable by the runner user
sudo chown -R runner:docker ~/flatcar-sdk/chroot/var

function enter() ( exec cork enter -- $@ )

# To be able to generate metadata, we need to configure a profile
# /etc/portage/make.profile, a symlink pointing to the SDK profile.
enter sudo eselect profile set --force "coreos:coreos/amd64/sdk"

# make edb directory group-writable to run egencache
enter sudo chmod g+w /var/cache/edb

git -C src/third_party/coreos-overlay reset --hard github/main
git -C src/third_party/coreos-overlay config user.name 'Flatcar Buildbot'
git -C src/third_party/coreos-overlay config user.email 'buildbot@flatcar-linux.org'
popd || exit

echo ::set-output name=path::"${PATH}"
