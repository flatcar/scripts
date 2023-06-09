#!/bin/bash

##
## Finds the latest nightly tag in the given scripts repo and creates a worktree with it.
##
## Parameters:
## -h: this help
##
## Positional:
## 0: scripts directory
## 1: where the worktree is supposed to be created
## 2: branch name for the worktree
##

set -euo pipefail

function fail {
    echo "${*}" >&2
    exit 1
}

this=${0}

if [[ ${#} -eq 1 ]] && [[ ${1} = '-h' ]]; then
    grep '^##' "${this}" | sed -e 's/##[[:space:]]*//'
    exit 0
fi

if [[ ${#} -ne 3 ]]; then
    fail 'Expected three parameters: a scripts directory, a worktree directory and a branch name'
fi

scripts=$(realpath "${1}")
worktree=$(realpath --canonicalize-missing "${2}")
branch=${3}

nightly_tag=$(git -C "${scripts}" describe --tags --match='main-*-nightly-*' --abbrev=0)

git -C "${scripts}" worktree add -b "${branch}" "${worktree}" "${nightly_tag}"
