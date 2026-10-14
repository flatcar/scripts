#!/bin/bash

set -euo pipefail

rootfs="${1}"

# chronyd Conflicts= with timesyncd; with both enabled, which one survives the
# boot transaction is a race. Mask timesyncd so chronyd always wins. This can't
# be done from the ebuild: the base image already owns the unit file and
# Portage's collision protection refuses to overwrite it.
ln -sf /dev/null "${rootfs}/usr/lib/systemd/system/systemd-timesyncd.service"
