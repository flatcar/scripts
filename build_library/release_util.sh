# Copyright (c) 2013 The CoreOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

GSUTIL_OPTS=
UPLOAD_ROOT=
UPLOAD_PATH=
TORCX_UPLOAD_ROOT=
UPLOAD_DEFAULT=${FLAGS_FALSE}
DEFAULT_IMAGE_COMPRESSION_FORMAT="bz2"

# Default upload root can be overridden from the environment.
_user="${USER}"
[[ ${USER} == "root" ]] && _user="${SUDO_USER}"
: ${FLATCAR_UPLOAD_ROOT:=gs://users.developer.core-os.net/${_user}}
: ${FLATCAR_TORCX_UPLOAD_ROOT:=${FLATCAR_UPLOAD_ROOT}/torcx}
unset _user

DEFINE_boolean parallel ${FLAGS_TRUE} \
  "Enable parallelism in gsutil."
DEFINE_boolean upload ${UPLOAD_DEFAULT} \
  "Upload all packages/images via gsutil."
DEFINE_boolean private ${FLAGS_TRUE} \
  "Upload the image as a private object."
DEFINE_string upload_root "${FLATCAR_UPLOAD_ROOT}" \
  "Upload prefix, board/version/etc will be appended. Must be a gs:// URL."
DEFINE_string upload_path "" \
  "Full upload path, overrides --upload_root. Must be a full gs:// URL."
DEFINE_string download_root "" \
  "HTTP download prefix, board/version/etc will be appended."
DEFINE_string download_path "" \
  "HTTP download path, overrides --download_root."
DEFINE_string torcx_upload_root "${FLATCAR_TORCX_UPLOAD_ROOT}" \
  "Tectonic torcx package and manifest Upload prefix. Must be a gs:// URL."
DEFINE_string tectonic_torcx_download_root "" \
  "HTTP download prefix for tectonic torcx packages and manifests."
DEFINE_string tectonic_torcx_download_path "" \
  "HTTP download path, overrides --tectonic_torcx_download_root."
DEFINE_string sign "" \
  "Sign all files to be uploaded with the given GPG key."
DEFINE_string sign_digests "" \
  "Sign image DIGESTS files with the given GPG key."
DEFINE_string image_compression_formats "${DEFAULT_IMAGE_COMPRESSION_FORMAT}" \
  "Compress the resulting images using thise formats. This option acceps a list of comma separated values. Options are: none, bz2, gz, zip, zstd"


compress_file() {
    local filepath="$1"
    local compression_format="$2"

    [ ! -f "${filepath}" ] && die "Image file ${filepath} does not exist"
    [ -z "${compression_format}" ] && die "compression format parameter is mandatory"

    case "${compression_format}" in
    "none"|"")
        echo -n "${filepath}"
        return 0
        ;;
    "bz2")
        IMAGE_ZIPPER="lbzip2 --compress --keep"
        ;;
    "gz")
        IMAGE_ZIPPER="pigz --keep"
        ;;
    "zip")
        IMAGE_ZIPPER="pigz --keep --zip"
        ;;
    "zstd")
       IMAGE_ZIPPER="zstd --format=zstd -k -q -f --no-progress -o ${filepath}.${compression_format}"
       ;;
    *)
        die "Unsupported compression format ${compression_format}"
        ;;
    esac

    ${IMAGE_ZIPPER} -f "${filepath}" 2>&1 >/dev/null || die "failed to compress ${filepath}"

    echo -n "${filepath}.${compression_format}"
}

compress_disk_images() {
    # An array of files that are to be evaluated and possibly compressed if images are
    # among them.
    local -n local_files_to_evaluate="$1"

    # An array that will hold the path on disk to the resulting disk image archives.
    # Multiple compression formats may be requested, so this array may hold
    # multiple archives for the same image.
    local -n local_resulting_archives="$2"

    # Files that did not match the filter for disk images.
    local -n local_extra_files="$3"

    info "Compressing images"
    # We want to compress images, but we also want to remove the uncompressed files
    # from the list of uploadable files.
    for filename in "${local_files_to_evaluate[@]}"; do
        if [[ "${filename}" =~ \.(img|bin|vdi|vhd|vmdk)$ ]]; then
            # Parse the formats as an array. This will yield an extra empty
            # array element at the end.
            readarray -td, FORMATS<<<"${FLAGS_image_compression_formats},"
            # unset the last element
            unset 'FORMATS[-1]'

            # An associative array we set an element on whenever we process a format.
            # This way we don't process the same format twice. A unique for array elements.
            declare -A processed_format
            for format in "${FORMATS[@]}";do
                if [ -z "${processed_format[${format}]}" ]; then
                    info "Compressing ${filename##*/} to ${format}"
                    COMPRESSED_FILENAME=$(compress_file "${filename}" "${format}")
                    local_resulting_archives+=( "$COMPRESSED_FILENAME" )
                    processed_format["${format}"]=1
                fi
            done
        else
            local_extra_files+=( "${filename}" )            
        fi
    done
}

upload_legacy_digests() {
    [[ ${FLAGS_upload} -eq ${FLAGS_TRUE} ]] || return 0

    local local_digest_file="$1"
    local -n local_compressed_files="$2"

    [[ "${#local_compressed_files[@]}" -gt 0 ]] || return 0

    # Upload legacy digests
    declare -a digests_to_upload
    for file in "${local_compressed_files[@]}";do
        legacy_digest_file="${file}.DIGESTS"
        cp "${local_digest_file}" "${legacy_digest_file}"
        digests_to_upload+=( "${legacy_digest_file}" )
    done
    local def_upload_path="${UPLOAD_ROOT}/boards/${BOARD}/${FLATCAR_VERSION}"
    upload_files "digests" "${def_upload_path}" "" "${digests_to_upload[@]}"
}

check_gsutil_opts() {
    [[ ${FLAGS_upload} -eq ${FLAGS_TRUE} ]] || return 0

    if [[ ${FLAGS_parallel} -eq ${FLAGS_TRUE} ]]; then
        GSUTIL_OPTS="-m"
    fi

    if [[ -n "${FLAGS_upload_root}" ]]; then
        if [[ "${FLAGS_upload_root}" != gs://* ]] \
           && [[ "${FLAGS_upload_root}" != rsync://* ]] ; then
            die_notrace "--upload_root must be a gs:// or rsync:// URL"
        fi
        # Make sure the path doesn't end with a slash
        UPLOAD_ROOT="${FLAGS_upload_root%%/}"
    fi

    if [[ -n "${FLAGS_torcx_upload_root}" ]]; then
        if [[ "${FLAGS_torcx_upload_root}" != gs://* ]] \
           && [[ "${FLAGS_torcx_upload_root}" != rsync://* ]] ; then
            die_notrace "--torcx_upload_root must be a gs:// or rsync:// URL"
        fi
        # Make sure the path doesn't end with a slash
        TORCX_UPLOAD_ROOT="${FLAGS_torcx_upload_root%%/}"
    fi

    if [[ -n "${FLAGS_upload_path}" ]]; then
        if [[ "${FLAGS_upload_path}" != gs://* ]] \
           && [[ "${FLAGS_upload_path}" != rsync://* ]] ; then
            die_notrace "--upload_path must be a gs:// or rsync:// URL"
        fi
        # Make sure the path doesn't end with a slash
        UPLOAD_PATH="${FLAGS_upload_path%%/}"
    fi

    # Ensure scripts run via sudo can use the user's gsutil/boto configuration.
    if [[ -n "${SUDO_USER}" ]]; then
        : ${BOTO_PATH:="$HOME/.boto:/home/$SUDO_USER/.boto"}
        export BOTO_PATH
    fi
}

# Generic upload function
# Usage: upload_files "file type" "${UPLOAD_ROOT}/default/path" "" files...
#  arg1: file type reported via log
#  arg2: default upload path, overridden by --upload_path
#  arg3: upload path suffix that can't be overridden, must end in /
#  argv: remaining args are files or directories to upload
upload_files() {
    [[ ${FLAGS_upload} -eq ${FLAGS_TRUE} ]] || return 0

    local msg="$1"
    local local_upload_path="$2"
    local extra_upload_suffix="$3"
    shift 3

    if [[ -n "${UPLOAD_PATH}" ]]; then
        local_upload_path="${UPLOAD_PATH}"
    fi

    if [[ -n "${extra_upload_suffix}" && "${extra_upload_suffix}" != */ ]]
    then
        die "upload suffix '${extra_upload_suffix}' doesn't end in /"
    fi

    info "Uploading ${msg} to ${local_upload_path}"

    if [[ "${local_upload_path}" = 'rsync://'* ]]; then
        local rsync_upload_path="${local_upload_path#rsync://}"
        local sshcmd="ssh -o BatchMode=yes "
              sshcmd="$sshcmd -o StrictHostKeyChecking=no"
              sshcmd="$sshcmd -o UserKnownHostsFile=/dev/null"
              sshcmd="$sshcmd -o NumberOfPasswordPrompts=0"

        # ensure the target path exists
        local sshuserhost="${rsync_upload_path%:*}"
        local destpath="${rsync_upload_path#*:}"
        ${sshcmd} "${sshuserhost}" \
            "mkdir -p ${destpath}/${extra_upload_suffix}"

        # now sync
        rsync -Pav -e "${sshcmd}" "$@" \
            "${rsync_upload_path}/${extra_upload_suffix}"
    else
        gsutil ${GSUTIL_OPTS} cp -R "$@" \
            "${local_upload_path}/${extra_upload_suffix}"
    fi
}


# Identical to upload_files but GPG signs every file if enabled.
# Usage: sign_and_upload_files "file type" "${UPLOAD_ROOT}/default/path" "" files...
#  arg1: file type reported via log
#  arg2: default upload path, overridden by --upload_path
#  arg3: upload path suffix that can't be overridden, must end in /
#  argv: remaining args are files or directories to upload
sign_and_upload_files() {
    [[ ${FLAGS_upload} -eq ${FLAGS_TRUE} ]] || return 0

    local msg="$1"
    local path="$2"
    local suffix="$3"
    shift 3

    # run a subshell to possibly clean the temporary directory with
    # signatures without clobbering the global EXIT trap
    (
    # Create simple GPG detached signature for all uploads.
    local sigs=()
    if [[ -n "${FLAGS_sign}" ]]; then
        local file
        local sigfile
        local sigdir=$(mktemp --directory)
        trap "rm -rf ${sigdir}" EXIT
        for file in "$@"; do
            if [[ "${file}" =~ \.(asc|gpg|sig)$ ]]; then
                continue
            fi

            for sigfile in $(find "${file}" ! -type d); do
                mkdir -p "${sigdir}/${sigfile%/*}"
                gpg --batch --local-user "${FLAGS_sign}" \
                    --output "${sigdir}/${sigfile}.sig" \
                    --detach-sign "${sigfile}" || die "gpg failed"
            done

            [ -d "${file}" ] &&
            sigs+=( "${sigdir}/${file}" ) ||
            sigs+=( "${sigdir}/${file}.sig" )
        done
    fi

    upload_files "${msg}" "${path}" "${suffix}" "$@" "${sigs[@]}"
    )
}

upload_packages() {
    [[ ${FLAGS_upload} -eq ${FLAGS_TRUE} ]] || return 0
    [[ -n "${BOARD}" ]] || die "board_options.sh must be sourced first"

    local board_packages="${1:-"${BOARD_ROOT}/packages"}"
    local def_upload_path="${UPLOAD_ROOT}/boards/${BOARD}/${FLATCAR_VERSION}"
    sign_and_upload_files packages ${def_upload_path} "pkgs/" \
        "${board_packages}"/*
}

# Upload a set of files (usually images) and digest, optionally w/ gpg sig
# If more than one file is specified -d must be the first argument
# Usage: upload_image [-d file.DIGESTS] file1 [file2...]
upload_image() {
    [[ ${FLAGS_upload} -eq ${FLAGS_TRUE} ]] || return 0
    [[ -n "${BOARD}" ]] || die "board_options.sh must be sourced first"

    # The name to use for .DIGESTS and .DIGESTS.asc must be explicit if
    # there is more than one file to upload to avoid potential confusion.
    local digests
    if [[ "$1" == "-d" ]]; then
        [[ -n "$2" ]] || die "-d requires an argument"
        digests="$2"
        shift 2
    else
        [[ $# -eq 1 ]] || die "-d is required for multi-file uploads"
        # digests is assigned after image is possibly compressed/renamed
    fi

    local uploads=()
    local filename
    for filename in "$@"; do
        if [[ ! -f "${filename}" ]]; then
            die "File '${filename}' does not exist!"
        fi
        uploads+=( "${filename}" )
    done

    if [[ -z "${digests}" ]]; then
        digests="${uploads[0]}.DIGESTS"
    fi

    # For consistency generate a .DIGESTS file similar to the one catalyst
    # produces for the SDK tarballs and up upload it too.
    make_digests -d "${digests}" "${uploads[@]}"
    uploads+=( "${digests}" )

    # Create signature as ...DIGESTS.asc as Gentoo does.
    if [[ -n "${FLAGS_sign_digests}" ]]; then
      rm -f "${digests}.asc"
      gpg --batch --local-user "${FLAGS_sign_digests}" \
          --clearsign "${digests}" || die "gpg failed"
      uploads+=( "${digests}.asc" )
    fi

    local log_msg=$(basename "$digests" .DIGESTS)
    local def_upload_path="${UPLOAD_ROOT}/boards/${BOARD}/${FLATCAR_VERSION}"
    sign_and_upload_files "${log_msg}" "${def_upload_path}" "" "${uploads[@]}"
}

# Translate the configured upload URL to a download URL
# Usage: download_image_url "path/suffix"
download_image_url() {
    if [[ ${FLAGS_upload} -ne ${FLAGS_TRUE} ]]; then
        echo "$1"
        return 0
    fi

    local download_root="${FLAGS_download_root:-${UPLOAD_ROOT}}"

    local download_path
    local download_channel
    if [[ -n "${FLAGS_download_path}" ]]; then
        download_path="${FLAGS_download_path%%/}"
    elif [[ "${download_root}" == *flatcar-jenkins* ]]; then
        download_channel="${download_root##*/}"
        download_root="gs://${download_channel}.release.flatcar-linux.net"
        # Official release download paths don't include the boards directory
        download_path="${download_root%%/}/${BOARD}/${FLATCAR_VERSION}"
    else
        download_path="${download_root%%/}/boards/${BOARD}/${FLATCAR_VERSION}"
    fi

    # Just in case download_root was set from UPLOAD_ROOT
    if [[ "${download_path}" == gs://* ]]; then
        download_path="https://${download_path#gs://}"
    fi

    echo "${download_path}/$1"
}

# Translate the configured torcx upload URL to a download url
# This is similar to the download_image_url, other than assuming the release
# bucket is the tectonic_torcx one.
download_tectonic_torcx_url() {
    if [[ ${FLAGS_upload} -ne ${FLAGS_TRUE} ]]; then
        echo "$1"
        return 0
    fi

    local download_root="${FLAGS_tectonic_torcx_download_root:-${TORCX_UPLOAD_ROOT}}"

    local download_path
    if [[ -n "${FLAGS_tectonic_torcx_download_path}" ]]; then
        download_path="${FLAGS_tectonic_torcx_download_path%%/}"
    else
        download_path="${download_root%%/}"
    fi

    # Just in case download_root was set from UPLOAD_ROOT
    if [[ "${download_path}" == gs://* ]]; then
        download_path="http://${download_path#gs://}"
    fi

    echo "${download_path}/$1"
}
