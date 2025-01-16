#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/impl/util.sh"

##
## Prints a diff of a package in old and new scripts
## directories. Operates in one of two modes. First mode is an
## "ebuild" mode where it shows a diff of two ebuilds. The other mode
## is an "other" mode where it shows diffs of all non-ebuild files
## (ignoring Manifest files too).
##
## Parameters:
## -h: this help
## -r <name>: New package name (useful when package got renamed)
##
## Positional:
## 1: mode, "ebuild" (or "e") or "other" (or "o")
## 2: path to old scripts repository
## 3: path to new scripts repository
## 4: package name (but see -r flag too)
## 5: old version (for "ebuild" mode only)
## 6: new version (for "ebuild" mode only)
##

renamed=

while [[ ${#} -gt 0 ]]; do
    case ${1} in
        -h)
            print_help
            exit 0
            ;;
        -r)
            renamed=${2}
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            fail "unknown flag ${1@Q}"
            ;;
        *)
            break
            ;;
    esac
done

if [[ ${#} -lt 1 ]]; then
    fail 'Use -h to get help'
fi

mode=${1}; shift

case ${mode} in
    ebuild|ebuil|ebui|ebu|eb|e)
        mode=e
        if [[ ${#} -ne 5 ]]; then
            fail 'Expected five positional parameters: a path to old and new scripts repositories, a package name, and old a new version of package'
        fi
        ;;
    other|othe|oth|ot|o)
        mode=o
        # expect at least three parameters, if more are given, they
        # will be ignored, to allow changing mode from ebuild to other
        # without the need for removing versions from the command
        # invocation
        if [[ ${#} -lt 3 ]]; then
            fail 'Expected three positional parameters: a path to old and new scripts repositories, and a package name'
        fi
        ;;
esac

old_scripts=${1}
new_scripts=${2}
# old and new package name
old_package=${3}
new_package=${renamed:-${3}}

gentoo_path=sdk_container/src/third_party/portage-stable
overlay_path=sdk_container/src/third_party/coreos-overlay
old_gentoo_path=${old_scripts}/${gentoo_path}/${old_package}
old_overlay_path=${old_scripts}/${overlay_path}/${old_package}
new_gentoo_path=${new_scripts}/${gentoo_path}/${new_package}
new_overlay_path=${new_scripts}/${overlay_path}/${new_package}

if [[ -e ${old_gentoo_path} ]] && [[ -e ${old_overlay_path} ]]; then
    fail "Package ${old_package@Q} exists in both gentoo and overlay in old scripts"
fi

if [[ -e ${new_gentoo_path} ]] && [[ -e ${new_overlay_path} ]]; then
    fail "Package ${new_package@Q} exists in both gentoo and overlay in new scripts"
fi

if [[ ${mode} = e ]]; then
    old_version=${4}
    new_version=${5}
    old_gentoo_ebuild=${old_gentoo_path}/${old_package#*/}-${old_version}.ebuild
    old_overlay_ebuild=${old_overlay_path}/${old_package#*/}-${old_version}.ebuild
    new_gentoo_ebuild=${new_gentoo_path}/${new_package#*/}-${new_version}.ebuild
    new_overlay_ebuild=${new_overlay_path}/${new_package#*/}-${new_version}.ebuild

    old_path=''
    new_path=''

    if [[ -e ${old_gentoo_ebuild} ]]; then
        old_path=${old_gentoo_ebuild}
    fi
    if [[ -e ${old_overlay_ebuild} ]]; then
        old_path=${old_overlay_ebuild}
    fi

    if [[ -e ${new_gentoo_ebuild} ]]; then
        new_path=${new_gentoo_ebuild}
    fi
    if [[ -e ${new_overlay_ebuild} ]]; then
        new_path=${new_overlay_ebuild}
    fi

    if [[ -z ${old_path} ]]; then
        fail "Old version ${old_version@Q} does not exist neither in overlay nor in gentoo"
    fi

    if [[ -z ${new_path} ]]; then
        fail "New version ${new_version@Q} does not exist neither in overlay nor in gentoo"
    fi

    diff --color --unified=3 "${old_path}" "${new_path}" || :
else
    old_path=${old_gentoo_path}
    new_path=${new_gentoo_path}

    if [[ -e ${old_overlay_path} ]]; then
        old_path=${old_overlay_path}
    fi

    if [[ -e ${new_overlay_path} ]]; then
        new_path=${new_overlay_path}
    fi

    diff --color --recursive --unified=3 --new-file --exclude='*.ebuild' --exclude='Manifest' "${old_path}" "${new_path}" || :
fi
