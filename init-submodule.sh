#!/bin/bash
#
# Initialise the Gentoo submodule

set -euo pipefail

force=false
latest=false
upstream_branch="master"

function usage() {
  echo "Usage: $0 [--force] [--upstream <branch>]"
  echo " Initialise Gentoo submodule."
  echo "   -f|--force     - force initialisation even if submodule is already initialised."
  echo "   -u|--upstream  - <branch> use upstream <branch> instead of '${upstream_branch}'."
  echo "   -l|--latest    - use latest upstream tip instead of pinned commit (see -u)."
}
# --

while [[ "$#" -gt 0 ]] ; do
  case "$1" in
    -f|--force)  force=true;;
    -l|--latest) latest=true;;
    -u|--upstream) shift; upstream_branch="$1";;
    -h|--help) usage; exit;;
    *) echo "ERROR: unknown argument '$1'"
       exit 1;;
  esac
  shift
done

if $force || git submodule status | grep -q '^-' ; then
  echo "Initialising submodule"
  git submodule update --init --depth 1 --single-branch
  git -C sdk_container/src/third_party/gentoo remote set-branches --add origin "${upstream_branch}"
  git -C sdk_container/src/third_party/gentoo fetch origin "${upstream_branch}" --depth 1
  if $latest; then
    git -C sdk_container/src/third_party/gentoo checkout "${upstream_branch}"
  fi
fi
