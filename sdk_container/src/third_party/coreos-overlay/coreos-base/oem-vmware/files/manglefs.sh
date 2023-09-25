#!/bin/bash

set -euo pipefail

rootfs=${1}

cd "${rootfs}"

# Move stuff out of /etc. The systemd unit files are patched to create
# symlinks from /etc to those directories.
mkdir -p usr/lib/pam.d
mv etc/pam.d/vmtoolsd usr/lib/pam.d/vmtoolsd
mkdir -p usr/share/flatcar/oem-vmware
mv etc/vmware-tools usr/share/flatcar/oem-vmware/vmware-tools

files_to_drop=(
    # Development stuff.
    usr/bin/dnet-config
    usr/bin/*xslt-config
    usr/bin/xmlsec1-config
    usr/lib64/*Conf.sh
)

dirs_to_drop=(
    # Debugging symbols.
    usr/lib/debug/
    # Translations.
    usr/share/open-vm-tools/messages/
    # Development stuff.
    usr/include/
    usr/lib64/cmake/
    usr/lib64/pkgconfig/
    usr/share/aclocal/
)

rm -f "${files_to_drop[@]}"
rm -rf "${dirs_to_drop[@]}"
