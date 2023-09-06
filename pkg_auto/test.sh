#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"
source "${PKG_AUTO_DIR}/pkg_auto_lib.sh"

summary_stubs=${1}

sort_like_summary_stubs "${summary_stubs}"
