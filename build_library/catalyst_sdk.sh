#!/bin/bash
set -e

source /tmp/chroot-functions.sh
source /tmp/toolchain_util.sh

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

echo "Saving snapshot of repos for future SDK bootstraps"
# Copy portage-stable and coreos-overlay, which are under
# /mnt/host/source/src/third_party, into a local directory because they are
# removed before archiving and we want to keep snapshots. These snapshots are
# used by stage 1 in future bootstraps.
mkdir -p /var/gentoo/repos/{gentoo,coreos-overlay}
cp -R /mnt/host/source/src/third_party/portage-stable/* /var/gentoo/repos/gentoo/
cp -R /mnt/host/source/src/third_party/coreos-overlay/* /var/gentoo/repos/coreos-overlay/
