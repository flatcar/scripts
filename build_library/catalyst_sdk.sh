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
# Copy gentoo-subset and flatcar-overlay, which are under
# /mnt/host/source/src/scripts/repos, into a local directory because they are
# removed before archiving and we want to keep snapshots. These snapshots are
# used by stage 1 in future bootstraps.
mkdir -p /var/gentoo/repos
cp -R /mnt/host/source/src/scripts/repos/{gentoo-subset,flatcar-overlay}/ /var/gentoo/repos/
