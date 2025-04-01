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
## -p: download packages SDK images instead of the standard one (valid
##     only when downloading docker images)
## -nl: skip downloading of listings
## -x <FILE>: cleanup file
##
## Positional:
## 1: downloads directory
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/impl/util.sh"
source "${PKG_AUTO_IMPL_DIR}/cleanups.sh"

CLEANUP_FILE=
SCRIPTS=
VERSION_ID=
BUILD_ID=
SKIP_DOCKER=
SKIP_LISTINGS=
PKGS_SDK=

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
        -p)
            PKGS_SDK=x
            shift
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

DOWNLOADS_DIR=$(realpath "${1}"); shift

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

if [[ ! -d "${DOWNLOADS_DIR}" ]]; then
    add_cleanup "rmdir ${DOWNLOADS_DIR@Q}"
    mkdir "${DOWNLOADS_DIR}"
fi

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
    # shellcheck source=for-shellcheck/version.txt
    VERSION_ID=$(source "${SCRIPTS}/sdk_container/.repo/manifests/version.txt"; printf '%s' "${FLATCAR_VERSION_ID}")
    # shellcheck source=for-shellcheck/version.txt
    BUILD_ID=$(source "${SCRIPTS}/sdk_container/.repo/manifests/version.txt"; printf '%s' "${FLATCAR_BUILD_ID}")
fi

ver_plus="${VERSION_ID}${BUILD_ID:++}${BUILD_ID}"
ver_dash="${VERSION_ID}${BUILD_ID:+-}${BUILD_ID}"

exts=(zst bz2 gz)

zst_cmds=(
    zstd
)

bz2_cmds=(
    lbunzip2
    pbunzip2
    bunzip2
)

gz_cmds=(
    unpigz
    gunzip
)

function download_sdk() {
    local image_name=${1}; shift
    local tarball_name=${1}; shift
    local url_dir=${1}; shift

    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q -x -F "${image_name}"; then
        return 0
    fi

    info "No ${image_name} available in docker, pulling it from bincache"
    local ext full_tarball_name tb
    for ext in "${exts[@]}"; do
        full_tarball_name="${tarball_name}.tar.${ext}"
        tb="${DOWNLOADS_DIR}/${full_tarball_name}"
        if [[ -s ${tb} ]]; then
            break;
        else
            add_cleanup "rm -f ${tb@Q}"
            if download "${url_dir}/${full_tarball_name}" "${tb}"; then
                break
            fi
        fi
    done
    info "Loading ${image_name} into docker"
    cmds_name="${ext}_cmds"
    if ! declare -p "${cmds_name}" >/dev/null 2>/dev/null; then
        fail "Failed to extract ${tb@Q} - no tools to extract ${ext@Q} files"
    fi
    declare -n cmds="${ext}_cmds"
    loaded=
    for cmd in "${cmds[@]}"; do
        if ! command -v "${cmd}" >/dev/null; then
            info "${cmd@Q} is not available"
            continue
        fi
        info "Using ${cmd@Q} to extract the tarball"
        "${cmd}" -d -c "${tb}" | docker load
        add_cleanup "docker rmi ${image_name@Q}"
        loaded=x
        break
    done
    if [[ -z ${loaded} ]]; then
        fail "Failed to extract ${tb@Q} - no known available tool to extract it"
    fi
    unset -n cmds
}

URL_DIR="https://bincache.flatcar-linux.net/containers/${ver_dash}"

if [[ -z ${SKIP_DOCKER} ]] && [[ -z ${PKGS_SDK} ]]; then
    download_sdk "ghcr.io/flatcar/flatcar-sdk-all:${ver_dash}" "flatcar-sdk-all-${ver_dash}" "${URL_DIR}"
fi

declare -a dsal_arches
get_valid_arches dsal_arches

for arch in "${dsal_arches[@]}"; do
    if [[ -z ${SKIP_DOCKER} ]] && [[ -n ${PKGS_SDK} ]]; then
        download_sdk "flatcar-packages-${arch}:${ver_dash}" "flatcar-packages-${arch}-${ver_dash}.tar.${ext}" "${URL_DIR}"
    fi

    if [[ -z ${SKIP_LISTINGS} ]]; then
        listing_dir="${DOWNLOADS_DIR}/${arch}"
        add_cleanup "rmdir ${listing_dir@Q}"
        mkdir "${listing_dir}"
        base_url="https://bincache.flatcar-linux.net/images/${arch}/${ver_plus}"

        for infix in '' 'rootfs-included-sysexts'; do
            index_html="${listing_dir}/${infix}${infix:+-}index.html"
            url="${base_url}${infix:+/}${infix}"
            add_cleanup "rm -f ${index_html@Q}"
            download "${url}/" "${index_html}"

            # get names of all files ending with _packages.txt
            mapfile -t listing_files < <(grep -F '_packages.txt"' "${index_html}" | sed -e 's#.*"\(\./\)\?\([^"]*\)".*#\2#')

            for listing in "${listing_files[@]}"; do
                info "Downloading ${listing} for ${arch}"
                listing_path="${listing_dir}/${listing}"
                add_cleanup "rm -f ${listing_path@Q}"
                download "${url}/${listing}" "${listing_path}"
            done
        done
    fi
done
info 'Done'
