#!/bin/bash

##
## Downloads package SDKs from bincache and loads them with
## docker. Downloads package listings from bincache. Version can be
## taken either from the latest nightly tag in the passed scripts
## directory (with the -s option) or from specified version ID and
## build ID (with -v and -b options). The results are written to the
## passed downloads directory.
##
## Parameters:
## -b <ID>: build ID, conflicts with -s
## -h: this help
## -s <DIR>: scripts repo directory, conflicts with -v and -b
## -v <ID>: version ID, conflicts with -s
## -nd: skip downloading of docker images
## -nl: skip downloading of listings
## -x <FILE>: cleanup file
##
## Positional:
## 1: downloads directory
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/impl/stuff.sh"

CLEANUP_FILE=
SCRIPTS=
VERSION_ID=
BUILD_ID=
SKIP_DOCKER=
SKIP_LISTINGS=

while [[ ${#} -gt 0 ]]; do
    case ${1} in
        -b)
            if [[ -n ${SCRIPTS} ]]; then
                fail '-b cannot be used at the same time with -s'
            fi
            if [[ -z ${2:-} ]]; then
                fail 'missing value for -b'
            fi
            BUILD_ID=${2}
            shift 2
            ;;
        -h)
            print_help
            exit 0
            ;;
        -s)
            if [[ -n ${VERSION_ID} ]] || [[ -n ${BUILD_ID} ]]; then
                fail '-s cannot be used at the same time with -v or -b'
            fi
            if [[ -z ${2:-} ]]; then
                fail 'missing value for -s'
            fi
            SCRIPTS=${2}
            shift 2
            ;;
        -v)
            if [[ -n ${SCRIPTS} ]]; then
                fail '-v cannot be used at the same time with -s'
            fi
            if [[ -z ${2:-} ]]; then
                fail 'missing value for -v'
            fi
            VERSION_ID=${2}
            shift 2
            ;;
        -x)
            if [[ -z ${2:-} ]]; then
                fail 'missing value for -x'
            fi
            CLEANUP_FILE=${2}
            shift 2
            ;;
        -nd)
            SKIP_DOCKER=x
            shift
            ;;
        -nl)
            SKIP_LISTINGS=x
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            fail "unknown flag '${1}'"
            ;;
        *)
            break
            ;;
    esac
done

if [[ ${#} -ne 1 ]]; then
    fail 'Expected one positional parameter: a downloads directory'
fi

DOWNLOADS_DIR=${1}; shift

if [[ -z ${SCRIPTS} ]] && [[ -z ${VERSION_ID} ]]; then
    fail 'need to pass either -s or -v (latter with the optional -b too)'
fi

if [[ -n ${CLEANUP_FILE} ]]; then
    dirname_out "${CLEANUP_FILE}" cleanup_dir
    # shellcheck disable=SC2154 # cleanup_dir is assigned in dirname_out
    mkdir -p "${cleanup_dir}"
    unset cleanup_dir
    setup_cleanups file "${CLEANUP_FILE}"
else
    setup_cleanups ignore
fi

add_cleanup "rmdir ${DOWNLOADS_DIR@Q}"
mkdir "${DOWNLOADS_DIR}"

function download() {
    local url output
    url="${1}"; shift
    output="${1}"; shift

    info "Downloading ${url}"
    curl \
        --fail \
        --show-error \
        --location \
        --retry-delay 1 \
        --retry 60 \
        --retry-connrefused \
        --retry-max-time 60 \
        --connect-timeout 20 \
        "${url}" >"${output}"
}

if [[ -n ${SCRIPTS} ]]; then
    # shellcheck disable=SC1091 # sourcing generated file
    VERSION_ID=$(source "${SCRIPTS}/sdk_container/.repo/manifests/version.txt"; printf '%s' "${FLATCAR_VERSION_ID}")
    # shellcheck disable=SC1091 # sourcing generated file
    BUILD_ID=$(source "${SCRIPTS}/sdk_container/.repo/manifests/version.txt"; printf '%s' "${FLATCAR_BUILD_ID}")
fi

ver_plus="${VERSION_ID}${BUILD_ID:++}${BUILD_ID}"
ver_dash="${VERSION_ID}${BUILD_ID:+-}${BUILD_ID}"

exts=(zst bz2 gz)

zst_cmd_1=zstd

bz2_cmd_1=lbunzip2
bz2_cmd_2=pbunzip2
bz2_cmd_3=bunzip2

gz_cmd_1=unpigz
gz_cmd_2=gunzip

for arch in amd64 arm64; do
    if [[ -z ${SKIP_DOCKER} ]]; then
        packages_image_name="flatcar-packages-${arch}:${ver_dash}"
        if ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q -x -F "${packages_image_name}"; then
            info "No ${packages_image_name} available in docker, pulling it from bincache"
            for ext in "${exts[@]}"; do
                tb="${DOWNLOADS_DIR}/packages-sdk-${arch}.tar.${ext}"
                add_cleanup "rm -f ${DOWNLOADS_DIR@Q}/packages-sdk-${arch}.tar.${ext}"
                if download "https://bincache.flatcar-linux.net/containers/${ver_dash}/flatcar-packages-${arch}-${ver_dash}.tar.${ext}" "${tb}"; then
                    break
                fi
            done
            info "Loading ${packages_image_name} into docker"
            for ((cmd_i=1; ; ++cmd_i)); do
                declare -n cmd=${ext}_${cmd_i}
                if [[ -n ${cmd:-} ]]; then
                    fail "Failed to extract ${tb@Q} - no known tool to extract it"
                fi
                if ! command -v "${cmd}" >/dev/null; then
                    info "${cmd@Q} is not available"
                    continue
                fi
                info "Using ${cmd@Q} to extract the tarball"
                ${cmd} -d -c "${tb}" | docker load
                add_cleanup "docker rmi ${packages_image_name@Q}"
                unset -n cmd
                break
            done
        fi
    fi

    if [[ -z ${SKIP_LISTINGS} ]]; then
        listing_dir="${DOWNLOADS_DIR}/${arch}"
        add_cleanup "rmdir ${listing_dir@Q}"
        mkdir "${listing_dir}"
        for listing in flatcar_production_image_packages.txt flatcar_developer_container_packages.txt; do
            info "Downloading ${listing} for ${arch}"
            listing_path="${listing_dir}/${listing}"
            add_cleanup "rm -f ${listing_path@Q}"
            download "https://bincache.flatcar-linux.net/images/${arch}/${ver_plus}/${listing}" "${listing_path}"
        done
    fi
done
info 'Done'
