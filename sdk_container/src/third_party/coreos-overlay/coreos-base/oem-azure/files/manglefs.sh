#!/bin/bash

set -euo pipefail

rootfs="${1}"

to_delete=(
    /usr/include
    /usr/lib/debug
    /usr/share/gdb
    /usr/lib64/pkgconfig
)

rm -rf "${to_delete[@]/#/${rootfs}}"

ln -sf /usr/bin/true "${rootfs}/usr/bin/eject"
