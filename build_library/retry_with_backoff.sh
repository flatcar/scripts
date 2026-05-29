#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# retry_with_backoff.sh — Retry a command with exponential backoff.
#
# Can be sourced for the `retry_with_backoff` function, or executed
# directly as a wrapper script.
#
# Usage (as script):
#   retry_with_backoff.sh [OPTIONS] -- COMMAND [ARGS...]
#
# Usage (as library):
#   source retry_with_backoff.sh
#   retry_with_backoff --max-attempts 3 -- my_function arg1 arg2
#
# Options:
#   --max-attempts N   Maximum number of attempts (default: 3)
#   --max-backoff  S   Maximum backoff in seconds (default: 300 = 5 min)
#   --initial-wait S   Initial wait in seconds before first retry (default: 15)
#   --clean-cmd CMD    Command to run between retries (e.g. cleanup)
#
# The backoff doubles each attempt: initial-wait, 2*initial-wait, ...
# capped at max-backoff.  Exits with the last attempt's exit code.

retry_with_backoff() {
    local max_attempts=3
    local max_backoff=300
    local initial_wait=15
    local clean_cmd=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --max-attempts) max_attempts="$2"; shift 2 ;;
            --max-backoff)  max_backoff="$2";  shift 2 ;;
            --initial-wait) initial_wait="$2"; shift 2 ;;
            --clean-cmd)    clean_cmd="$2";    shift 2 ;;
            --)             shift; break ;;
            *)              break ;;
        esac
    done

    if [[ $# -eq 0 ]]; then
        echo "##[error]retry_with_backoff: no command specified" >&2
        return 1
    fi

    local attempt=1
    local backoff="$initial_wait"

    while true; do
        echo "##[group]Attempt ${attempt}/${max_attempts}"
        echo "[retry] Running: $*"

        local rc=0
        "$@" || rc=$?

        if [[ $rc -eq 0 ]]; then
            echo "[retry] ✓ Succeeded on attempt ${attempt}"
            echo "##[endgroup]"
            return 0
        fi

        echo "##[warning][retry] Attempt ${attempt}/${max_attempts} failed (exit code ${rc})"
        echo "##[endgroup]"

        if [[ $attempt -ge $max_attempts ]]; then
            echo "##[error][retry] All ${max_attempts} attempts exhausted. Last exit code: ${rc}"
            return "$rc"
        fi

        # Cap backoff at maximum
        if [[ $backoff -gt $max_backoff ]]; then
            backoff=$max_backoff
        fi

        # Run cleanup immediately after failure to free resources
        if [[ -n "$clean_cmd" ]]; then
            echo "[retry] Running cleanup: ${clean_cmd}"
            $clean_cmd || echo "##[warning][retry] Cleanup command failed (non-fatal)"
        fi

        echo "[retry] Waiting ${backoff}s before retry..."
        sleep "$backoff"

        backoff=$((backoff * 2))
        attempt=$((attempt + 1))
    done
}

# When executed directly (not sourced), act as a wrapper script.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -uo pipefail
    retry_with_backoff "$@"
fi
