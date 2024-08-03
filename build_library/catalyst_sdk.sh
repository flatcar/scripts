#!/bin/bash
set -e

source /tmp/chroot-functions.sh
source /tmp/toolchain_util.sh

ln -vsfT "$(portageq get_repo_path / coreos-overlay)/coreos/user-patches" \
    /etc/portage/patches

echo "Double checking everything is fresh and happy."
run_merge -uDN --with-bdeps=y world

echo "Setting the default Python interpreter"
eselect python update

echo "Building cross toolchain for the SDK."
configure_crossdev_overlay / /usr/local/portage/crossdev

for cross_chost in $(get_chost_list); do
    echo "Building cross toolchain for ${cross_chost}"
    PKGDIR="$(portageq envvar PKGDIR)/crossdev" \
        install_cross_toolchain "${cross_chost}" ${clst_myemergeopts}
    PKGDIR="$(portageq envvar PKGDIR)/crossdev" \
        install_cross_rust "${cross_chost}" ${clst_myemergeopts}
done
