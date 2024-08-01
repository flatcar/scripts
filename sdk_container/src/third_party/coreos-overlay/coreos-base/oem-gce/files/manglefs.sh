#!/bin/bash

set -euo pipefail

rootfs="${1}"

rm -rf "${rootfs}"/usr/lib/debug
