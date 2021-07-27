#!/bin/bash
set -ex

SCRIPTFOLDER="$(dirname "$(readlink -f "$0")")"
"${SCRIPTFOLDER}/qemu_common.sh" qemu
