#!/bin/bash
#
# Initialise the Gentoo submodule

set -euo pipefail

force=false

while [[ "$#" -gt 0 ]] ; do
  case "$1" in
    --force|-f) force=true;;
    *) echo "ERROR: unknown argument '$1'"
       exit 1;;
  esac
  shift
done

if $force || git submodule status | grep -q '^-' ; then
  echo "Initialising submodules"
  git submodule update --init --depth 1 --single-branch
  git -C sdk_container/src/third_party/gentoo remote set-branches --add origin master
  git -C sdk_container/src/third_party/gentoo fetch origin master --depth 1
fi
