#!/bin/bash

set -euo pipefail

rootfs=${1}

# Remove test stuff from python - it's quite large.
for p in "${rootfs}"/usr/lib/python*; do
    if [[ ! -d ${p} ]]; then
        continue
    fi
    # find directories named tests or test and remove them (-prune
    # avoids searching below those directories)
    find "${p}" \( -name tests -o -name test \) -type d -prune -exec rm -rf '{}' '+'
done
