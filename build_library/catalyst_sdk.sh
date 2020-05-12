#!/bin/bash
set -e

source /tmp/chroot-functions.sh
source /tmp/toolchain_util.sh

echo "Double checking everything is fresh and happy."
run_merge -uDN --with-bdeps=y world

echo "Setting the default Python interpreter to Python 2."
eselect python set python2.7

echo "Building cross toolchain for the SDK."
configure_crossdev_overlay / /tmp/crossdev

for cross_chost in $(get_chost_list); do
    echo "Building cross toolchain for ${cross_chost}"
    PKGDIR="$(portageq envvar PKGDIR)/crossdev" \
        install_cross_toolchain "${cross_chost}" ${clst_myemergeopts}
    PKGDIR="$(portageq envvar PKGDIR)/crossdev" \
        install_cross_rust "${cross_chost}" ${clst_myemergeopts}
done
