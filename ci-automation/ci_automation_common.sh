#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# CI automation common functions.

source ci-automation/ci-config.env
: ${PIGZ:=pigz}
: ${docker:=docker}

: ${TEST_WORK_DIR:='__TESTS__'}

function check_version_string() {
    local version="$1"

    if [[ ! "${version}" =~ ^(main|alpha|beta|stable|lts)-[0-9]+\.[0-9]+\.[0-9]+(-.+)?$ ]]; then
        echo "ERROR: invalid version '${version}', must start with 'main', 'alpha', 'beta', 'stable' or 'lts', followed by a dash and three dot-separated numbers, optionally followed by a dash and a non-empty build ID"
        exit 1
    fi
}
# --

function update_and_push_version() {
    local version="$1"
    local push_to_branch="${2:-false}"

    # set up author and email so git does not complain when tagging
    if ! git config --get user.name >/dev/null 2>&1 ; then
        git -C . config user.name "${CI_GIT_AUTHOR}"
    fi
    if ! git config --get user.email >/dev/null 2>&1 ; then
        git -C . config user.email "${CI_GIT_EMAIL}"
    fi

    # Add and commit local changes
    git add "sdk_container/.repo/manifests/version.txt"

    git commit --allow-empty -m "New version: ${version}"

    git fetch --all --tags --force
    local ret=0
    git diff --exit-code "${version}" || ret=$?
    # This will return != 0 if
    #  - the remote tag does not exist (rc: 127)
    #  - the tag does not exist locally (rc: 128)
    #  - the remote tag has changes compared to the local tree (rc: 1)
    if [ "$ret" = "0" ]; then
      echo "Reusing existing tag" >&2
      git checkout -f "${version}"
      return
    elif [ "$ret" = "1" ]; then
      echo "Remote tag exists already and is not equal" >&2
      return 1
    elif [ "$ret" != "127" ] && [ "$ret" != "128" ]; then
      echo "Error: Unexpected git diff return code ($ret)" >&2
      return 1
    fi

    local -a TAG_ARGS
    if [ "${SIGN-0}" = 1 ]; then
      TAG_ARGS=("-s" "-m" "${version}")
    fi

    git tag -f "${TAG_ARGS[@]}" "${version}"

    if [ "${push_to_branch}" = "true" ]; then
      local branch="$(git rev-parse --abbrev-ref HEAD)"
      git push origin "${branch}"
    fi

    git push origin "${version}"
}
# --

function copy_from_buildcache() {
    local what="$1"
    local where_to="$2"

    mkdir -p "$where_to"
    curl --fail --silent --show-error --location --retry-delay 1 --retry 60 \
        --retry-connrefused --retry-max-time 60 --connect-timeout 20 \
        --remote-name --output-dir "${where_to}" "https://${BUILDCACHE_SERVER}/${what}" 
}
# --

function gen_sshcmd() {
    echo -n "ssh -o BatchMode=yes"
    echo -n " -o StrictHostKeyChecking=no"
    echo -n " -o UserKnownHostsFile=/dev/null"
    echo    " -o NumberOfPasswordPrompts=0"
}
# --

function copy_dir_from_buildcache() {
    local remote_path="${BUILDCACHE_PATH_PREFIX}/$1"
    local local_path="$2"

    local sshcmd="$(gen_sshcmd)"
    mkdir -p "${local_path}"
    rsync --partial -a -e "${sshcmd}" "${BUILDCACHE_USER}@${BUILDCACHE_SERVER}:${remote_path}" \
        "${local_path}"
}

# --

function copy_to_buildcache() {
    local remote_path="${BUILDCACHE_PATH_PREFIX}/$1"
    shift

    local sshcmd="$(gen_sshcmd)"

    $sshcmd "${BUILDCACHE_USER}@${BUILDCACHE_SERVER}" \
        "mkdir -p ${remote_path}"

    rsync --partial -a -e "${sshcmd}" "$@" \
        "${BUILDCACHE_USER}@${BUILDCACHE_SERVER}:${remote_path}"
}
# --

function image_exists_locally() {
    local name="$1"
    local version="$2"
    local image="${name}:${version}"

    local image_exists="$($docker images "${image}" \
                            --no-trunc --format '{{.Repository}}:{{.Tag}}')"

    [ "${image}" = "${image_exists}" ]
}
# --

# Derive docker-safe image version string from vernum.
# Keep in sync with sdk_lib/sdk_container_common.sh
function vernum_to_docker_image_version() {
    local vernum="$1"
    echo "$vernum" | sed 's/[+]/-/g'
}
# --

# Return the full name (repo+name+tag) of an image. Useful for SDK images
#  pulled from the registry (which have the registry pre-pended)
function docker_image_fullname() {
    local image="$1"
    local version="$2"

    $docker images --no-trunc --format '{{.Repository}}:{{.Tag}}' \
        | grep -E "^(${CONTAINER_REGISTRY}/)*${image}:${version}$"
}
# --

function docker_image_to_buildcache() {
    local image="$1"
    local version="$2"

    # strip potential container registry prefix
    local tarball="$(basename "$image")-${version}.tar.gz"
    local id_file="$(basename "$image")-${version}.id"

    $docker save "${image}":"${version}" | $PIGZ -c > "${tarball}"
    # Cut the "sha256:" prefix that is present in Docker but not in Podman
    $docker image inspect "${image}":"${version}" | jq -r '.[].Id' | sed 's/^sha256://' > "${id_file}"
    create_digests "${SIGNER:-}" "${tarball}" "${id_file}"
    sign_artifacts "${SIGNER:-}" "${tarball}"* "${id_file}"*
    copy_to_buildcache "containers/${version}" "${tarball}"* "${id_file}"*
}
# --

function docker_commit_to_buildcache() {
    local container="$1"
    local image_name="$2"
    local image_version="$3"

    $docker commit "${container}" "${image_name}:${image_version}"
    docker_image_to_buildcache "${image_name}" "${image_version}"
}
# --

function docker_image_from_buildcache() {
    local name="$1"
    local version="$2"
    local tgz="${name}-${version}.tar.gz"
    local id_file="${name}-${version}.id"
    local id_file_url="https://${BUILDCACHE_SERVER}/containers/${version}/${id_file}"
    local id_file_url_release="https://mirror.release.flatcar-linux.net/containers/${version}/${id_file}"

    if image_exists_locally "${name}" "${version}" ; then
        local image_id=""
        image_id=$($docker image inspect "${name}:${version}" | jq -r '.[].Id' | sed 's/^sha256://')
        local remote_id=""
        remote_id=$(curl --fail --silent --show-error --location --retry-delay 1 \
                    --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 \
                    "${id_file_url}" \
                    || curl --fail --silent --show-error --location --retry-delay 1 \
                    --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 \
                    "${id_file_url_release}" \
                    || echo "not found")
        if [ "${image_id}" = "${remote_id}" ]; then
          echo "Local image is up-to-date" >&2
          return
        fi
        echo "Local image outdated, downloading..." >&2
    fi

    # First try bincache then release to allow a bincache overwrite
    local url="https://${BUILDCACHE_SERVER}/containers/${version}/${tgz}"
    local url_release="https://mirror.release.flatcar-linux.net/containers/${version}/${tgz}"

    curl --fail --silent --show-error --location --retry-delay 1 --retry 60 \
        --retry-connrefused --retry-max-time 60 --connect-timeout 20 \
        --remote-name "${url}" \
        || curl --fail --silent --show-error --location --retry-delay 1 --retry 60 \
        --retry-connrefused --retry-max-time 60 --connect-timeout 20 \
        --remote-name "${url_release}"

    cat "${tgz}" | $PIGZ -d -c | $docker load

    rm "${tgz}"
}
# --

function docker_image_from_registry_or_buildcache() {
    local image="$1"
    local version="$2"

    if $docker pull "${CONTAINER_REGISTRY}/${image}:${version}" ; then
        return
    fi

    echo "Falling back to tar ball download..." >&2
    docker_image_from_buildcache "${image}" "${version}"
}
# --

# Called by vendor test in case of complete failure not eligible for
# reruns (like trying to run tests on unsupported architecture).
function break_retest_cycle() {
    local work_dir=$(dirname "${PWD}")
    local dir=$(basename "${work_dir}")

    if [[ "${dir}" != "${TEST_WORK_DIR}" ]]; then
        echo "Not breaking retest cycle, expected test work dir to be a parent directory" >&2
        return
    fi
    touch "${work_dir}/break_retests"
}
# --

# Called by test runner to see if the retest cycle should be broken.
function retest_cycle_broken() {
    # Using the reverse boolean logic here!
    local broken=1
    if [[ -f "${TEST_WORK_DIR}/break_retests" ]]; then
        broken=0
        rm -f "${TEST_WORK_DIR}/break_retests"
    fi
    return ${broken}
}
# --

# Substitutes fields in the passed template and prints the
# result. Followed by the template, the parameters used for
# replacement are in alphabetical order: arch, channel, proto and
# vernum.
function url_from_template() {
    local template="${1}"; shift
    local arch="${1}"; shift
    local channel="${1}"; shift
    local proto="${1}"; shift
    local vernum="${1}"; shift
    local url="${template}"

    url="${url//@ARCH@/${arch}}"
    url="${url//@CHANNEL@/${channel}}"
    url="${url//@PROTO@/${proto}}"
    url="${url//@VERNUM@/${vernum}}"

    echo "${url}"
}
# --

# Puts a secret into a file, while trying for the secret to not end up
# on a filesystem at all. A path to the file with the secret in /proc
# in put into the chosen variable. The secret is assumed to be
# base64-encoded.
#
# Typical use:
#   secret_file=''
#   secret_to_file secret_file "${some_secret}"
#
# Parameters:
# 1 - name of the variable where the path is stored
# 2 - the secret to store in the file
function secret_to_file() {
    local config_var_name="${1}"; shift
    local secret="${1}"; shift
    local tmpfile=$(mktemp)
    local -n config_ref="${config_var_name}"
    local fd

    exec {fd}<>"${tmpfile}"
    rm -f "${tmpfile}"
    echo "${secret}" | base64 --decode >&${fd}
    # Use BASHPID because we may be in a subshell but $$ is only the main shell's PID
    config_ref="/proc/${BASHPID}/fd/${fd}"
}
# --

# Creates signatures for the passed files and directories. In case of
# directory, all files inside are signed. Files ending with .asc or
# .sig or .gpg are ignored, though. This function is a noop if signer
# is empty.
#
# Typical use:
#   sign_artifacts "${SIGNER}" artifact.tar.gz
#   copy_to_buildcache "artifacts/directory" artifact.tar.gz*
#
# Parameters:
#
# 1 - signer whose key is expected to be already imported into the
#       keyring
# @ - files and directories to sign
function sign_artifacts() {
    local signer="${1}"; shift
    # rest of the parameters are directories/files to sign
    local to_sign=()
    local file

    if [[ -z "${signer}" ]]; then
        return
    fi

    list_files to_sign 'asc,gpg,sig' "${@}"

    for file in "${to_sign[@]}"; do
        gpg --batch --local-user "${signer}" \
            --output "${file}.sig" \
            --detach-sign "${file}"
    done
}
# --

# Creates digests files and armored ASCII files out of them for the
# passed files and directories. In case of directory, all files inside
# it are processed. No new digests file is created if there is one
# already for the processed file. Same for armored ASCII file. Files
# ending with .asc or .sig or .gpg or .DIGESTS are not processed. The
# armored ASCII files won't be created if the signer is empty.
#
# Typical use:
#   create_digests "${SIGNER}" artifact.tar.gz
#   sign_artifacts "${SIGNER}" artifact.tar.gz*
#   copy_to_buildcache "artifacts/directory" artifact.tar.gz*
#
# Parameters:
#
# 1 - signer whose key is expected to be already imported into the
#       keyring
# @ - files and directories to create digests for
function create_digests() {
    local signer="${1}"; shift
    # rest of the parameters are files or directories to create
    # digests for
    local to_digest=()
    local file
    local df
    local fbn
    local hash_type
    local output
    local af

    list_files to_digest 'asc,gpg,sig,DIGESTS' "${@}"

    for file in "${to_digest[@]}"; do
        df="${file}.DIGESTS"
        if [[ ! -e "${df}" ]]; then
            touch "${df}"
            fbn=$(basename "${file}")
            # TODO: modernize - drop md5 and sha1, add b2
            for hash_type in md5 sha1 sha512; do
                echo "# ${hash_type} HASH" | tr "a-z" "A-Z" >>"${df}"
                output=$("${hash_type}sum" "${file}")
                echo "${output%% *}  ${fbn}" >>"${df}"
            done
        fi
        if [[ -z "${signer}" ]]; then
            continue
        fi
        af="${df}.asc"
        if [[ ! -e "${af}" ]]; then
            gpg --batch --local-user "${signer}" \
                --output "${af}" \
                --clearsign "${df}"
        fi
    done
}
# --

# Puts a filtered list of files from the passed files and directories
# in the passed variable. The filtering is done by ignoring files that
# end with the passed extensions. The extensions list should not
# contain the leading dot.
#
# Typical use:
#   local all_files=()
#   local ignored_extensions='sh,py,pl' # ignore the shell, python and perl scripts
#   list_files all_files "${ignored_extensions}" "${directories_and_files[@]}"
#
# Parameters:
#
# 1 - name of an array variable where the filtered files will be stored
# 2 - comma-separated list of extensions that will be used for filtering files
# @ - files and directories to scan for files
function list_files() {
    local files_variable_name="${1}"; shift
    local ignored_extensions="${1}"; shift
    # rest of the parameters are files or directories to list
    local -n files="${files_variable_name}"
    local file
    local tmp_files
    local pattern=''

    if [[ -n "${ignored_extensions}" ]]; then
        pattern='\.('"${ignored_extensions//,/|}"')$'
    fi

    files=()
    for file; do
        tmp_files=()
        if [[ -d "${file}" ]]; then
            readarray -d '' tmp_files < <(find "${file}" ! -type d -print0)
        elif [[ -e "${file}" ]]; then
            tmp_files+=( "${file}" )
        fi
        if [[ -z "${pattern}" ]]; then
            files+=( "${tmp_files[@]}" )
            continue
        fi
        for file in "${tmp_files[@]}"; do
            if [[ "${file}" =~ ${pattern} ]]; then
                continue
            fi
            files+=( "${file}" )
        done
    done
}
# --

# Applies ../scripts.patch to the current repo.
function apply_local_patches() {
  local patch_file="../scripts.patch"
  local patch_id
  echo "Looking for local patches ${patch_file}"
  patch_id=$(test -e "${patch_file}" && { cat "${patch_file}" | git patch-id | cut -d ' ' -f 1 ; } || true)
  if [ "${patch_id}" != "" ]; then
    if git "${dirarg[@]}" log --no-merges -p HEAD | git patch-id | cut -d ' ' -f 1 | grep -q "${patch_id}"; then
      echo "Skipping already applied ${patch_file}"
    else
      echo "Applying ${patch_file}"
      GIT_COMMITTER_NAME="Flatcar Buildbot" GIT_COMMITTER_EMAIL="buildbot@flatcar-linux.org" git am -3 "$PWD/${patch_file}"
    fi
  fi
}
# --

# Returns 0 if passed value is either "1" or "true" or "t", otherwise
# returns 1.
function bool_is_true() {
    case "${1}" in
        1|true|t|yes|y)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}
# --
