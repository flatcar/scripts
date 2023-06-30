#!/bin/bash

##
## Downloads package listings for various parts of Flatcar (developer
## container, production image)
##
## Parameters:
## -h: this help
##
## Positional:
## 0: Flatcar version
## 1: output directory
##
## Environment variables:
## ARCHES: Comma-separated list of architectures. If empty,
## amd64,arm64 is used.
## KINDS: Comma-separated list of image kinds. If empty,
## production_image,developer_container is used.
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
    fail 'Expected two parameters: a Flatcar version and an output directory'
fi

: "${ARCHES:=amd64,arm64}"
: "${KINDS:=production_image,developer_container}"

version=${1}
directory=${2}

function download {
    local url="${1}"; shift
    local output="${1}"; shift

    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --retry-delay 1 \
        --retry 60 \
        --retry-connrefused \
        --retry-max-time 60 \
        --connect-timeout 20 \
        "${url}" >"${output}"
}

mkdir -p "${directory}"

mapfile -t arches <(tr ',' '\n' <<<"${ARCHES}")
mapfile -t kinds <(tr ',' '\n' <<<"${KINDS}")

for arch in "${arches[@]}"; do
    for kind in "${kinds[@]}"; do
        echo "Downloading packages file for ${arch} ${kind}"
        download "https://bincache.flatcar-linux.net/images/${arch}/${flatcar_version}/flatcar_${kind}_packages.txt" "${directory}/packages-${kind}-${arch}"
    done
done
