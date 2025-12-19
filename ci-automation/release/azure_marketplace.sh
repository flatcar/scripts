#!/bin/bash

# Copyright (c) 2025 The Flatcar Maintainers.
# Use of this source code is governed by the Apache 2.0 license.

function release_azure_marketplace() {
    # Run a subshell, so the traps, environment changes and global
    # variables are not spilled into the caller.
    (
        set -euo pipefail

        _release_azure_marketplace_impl "${@}"
    )
}


function _release_azure_marketplace_impl() {
  source sdk_lib/sdk_container_common.sh
  source ci-automation/ci_automation_common.sh
  source ci-automation/gpg_setup.sh

  source sdk_container/.repo/manifests/version.txt

  # todo: update the vernum and the channel values.
  # they are currently hardcoded to test.
  local vernum="4547.0.0"
  local channel=
  channel="alpha"
  docker run --rm -it \
    -v ci-automation/release/azure_marketplace_publish.py:/app/azure_marketplace_publish.py \
    --env-file sdk_container/.env \
    -w /app \
    ghcr.io/astral-sh/uv:alpine \
    uv run azure_marketplace_publish.py \
      -p "${channel}"
      -v "${vernum}"
}
