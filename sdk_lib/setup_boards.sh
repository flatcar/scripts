#!/bin/bash

# Script used in Dockerfile.sdk-build. The failure is indicated by the
# BUILD_PACKAGES_FAILED file in the scripts directory in the built
# docker image. We do it to be able to recover the build logs from
# failed builds too.

set -euo pipefail

phase=${1}; shift
case ${phase} in

    start)
        binhost=${1}; shift
        if ! ( ./setup_board --board="arm64-usr" --binhost="${binhost}/arm64-usr" && \
                   ./setup_board --board="arm64-usr" --regen_configs && \
                   ./build_packages --board="arm64-usr" --only_resolve_circular_deps && \
                   \
                   ./setup_board --board="amd64-usr" --binhost="${binhost}/amd64-usr" && \
                   ./setup_board --board="amd64-usr" --regen_configs && \
                   ./build_packages --board="amd64-usr" --only_resolve_circular_deps ); then
            touch BUILD_PACKAGES_FAILED
        fi
        exit 0
        ;;

    finish)
        logdir=''
        if [[ ${#} -gt 0 ]]; then
            logdir=${1}; shift
        fi
        if [[ -n ${logdir} ]]; then
            for arch in amd64 arm64; do
                cp -a "/build/${arch}-usr/var/log/portage" "${logdir}/${arch}-package-logs"
            done
        fi
        if [[ -e BUILD_PACKAGES_FAILED ]]; then
            exit 1
        fi
        exit 0
        ;;

    *)
        echo "wrong phase ${phase@Q}" >&2
        exit 1
        ;;

esac
