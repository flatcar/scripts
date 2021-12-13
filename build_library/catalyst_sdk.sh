#!/bin/bash
set -e

source /tmp/chroot-functions.sh
source /tmp/toolchain_util.sh

echo "Double checking everything is fresh and happy."
run_merge -uDN --with-bdeps=y world

echo "Setting the default Python interpreter"
eselect python update

echo "Building cross toolchain for the SDK."
configure_crossdev_overlay / /tmp/crossdev

for cross_chost in $(get_chost_list); do
    echo "Building cross toolchain for ${cross_chost}"
    PKGDIR="$(portageq envvar PKGDIR)/crossdev" \
        install_cross_toolchain "${cross_chost}" ${clst_myemergeopts}
    PKGDIR="$(portageq envvar PKGDIR)/crossdev" \
        install_cross_rust "${cross_chost}" ${clst_myemergeopts}
done

echo "Saving snapshot of coreos-overlay repo for future SDK bootstraps"
# Copy coreos-overlay, which is in /var/gentoo/repos/local/, into a
# local directory.  /var/gentoo/repos/local/ is removed before archiving
# and we want to keep a snapshot. This snapshot is used - alongside
# /var/gentoo/repos/gentoo - by stage 1 of future bootstraps.
mkdir -p /var/gentoo/repos/coreos-overlay
cp -R /var/gentoo/repos/local/* /var/gentoo/repos/coreos-overlay
