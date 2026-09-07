#!/bin/bash
set -euo pipefail

exec systemd-run \
  --user \
  --scope \
  --collect \
  --same-dir \
  --expand-environment=no \
  "${@}"
