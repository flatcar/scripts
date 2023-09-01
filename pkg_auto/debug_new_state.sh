#!/bin/bash

##
## Enters the SDK using new state directory to debug issues.
##
## Parameters:
## -h: this help
##
## Positional:
## 1 - work directory
## 2 - arch (amd64 or arm64)
##

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/stuff.sh"

while [[ ${#} -gt 0 ]]; do
    case ${1} in
        -h)
            print_help
            exit 0
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

if [[ ${#} -ne 2 ]]; then
    fail 'Expected two parameters: work directory and board architecture'
fi

setup_cleanups trap

function main() {
    local workdir arch
    workdir=${1}; shift
    arch=${1}; shift

    local image_var_name
    image_var_name="${arch^^}_PACKAGES_IMAGE"
    # shellcheck disable=SC1091 # generated file
    source "${workdir}/globals"

    pushd "${NEW_STATE}"

    add_cleanup "rm -f ${NEW_STATE@Q}/{print_profile_tree.sh,inside_sdk_container.sh,stuff.sh}"
    cp -a "${PKG_AUTO_DIR}"/{print_profile_tree.sh,inside_sdk_container.sh,stuff.sh} .
    add_cleanup "git -C ${NEW_STATE@Q} checkout -- sdk_container/.repo/manifests/version.txt"
    ./run_sdk_container -t -C "${!image_var_name}" -a "${arch}" --rm
    popd
}

main "${@}"
