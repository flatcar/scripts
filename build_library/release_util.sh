# Copyright (c) 2013 The CoreOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

DEFAULT_IMAGE_COMPRESSION_FORMAT="bz2"

DEFINE_string image_compression_formats "${DEFAULT_IMAGE_COMPRESSION_FORMAT}" \
  "Compress the resulting images using thise formats. This option acceps a list of comma separated values. Options are: none, bz2, gz, zip, zst"
DEFINE_boolean only_store_compressed ${FLAGS_TRUE} \
  "Delete input file when compressing, except when 'none' is part of the compression formats or the generic image is the input"


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
    "zst")
       IMAGE_ZIPPER="zstd --format=zstd -k -q --no-progress"
       ;;
    *)
        die "Unsupported compression format ${compression_format}"
        ;;
    esac

    # Check if symlink in which case we set up a "compressed" symlink
    local compressed_name="${filepath}.${compression_format}"
    if [ -L "${filepath}" ]; then
        # We could also test if the target exists and otherwise do the compression
        # but we might then end up with two different compressed artifacts
        local link_target
        link_target=$(readlink -f "${filepath}")
        local target_basename
        target_basename=$(basename "${link_target}")
        ln -fs "${target_basename}.${compression_format}" "${compressed_name}"
    else
        ${IMAGE_ZIPPER} -f "${filepath}" 2>&1 >/dev/null || die "failed to compress ${filepath}"
    fi

    echo -n "${compressed_name}"
}

compress_disk_images() {
    # An array of files that are to be evaluated and possibly compressed if images are
    # among them.
    local -n local_files_to_evaluate="$1"

    info "Compressing ${#local_files_to_evaluate[@]} images"
    # We want to compress images, but we also want to remove the uncompressed files
    # from the list of uploadable files.
    for filename in "${local_files_to_evaluate[@]}"; do
        if [[ "${filename}" =~ \.(img|bin|vdi|vhd|vhdx|vmdk|qcow[2]?)$ ]]; then
            # Parse the formats as an array. This will yield an extra empty
            # array element at the end.
            readarray -td, FORMATS<<<"${FLAGS_image_compression_formats},"
            # unset the last element
            unset 'FORMATS[-1]'

            # An associative array we set an element on whenever we process a format.
            # This way we don't process the same format twice. A unique for array elements.
            # (But first we need to unset the previous loop or we can only compress a single
            # file per list of files).
            unset processed_format
            declare -A processed_format
            for format in "${FORMATS[@]}";do
                if [ -z "${processed_format[${format}]}" ]; then
                    info "Compressing ${filename##*/} to ${format}"
                    COMPRESSED_FILENAME=$(compress_file "${filename}" "${format}")
                    processed_format["${format}"]=1
                fi
            done
            # If requested, delete the input file after compression (only if 'none' is not part of the formats)
            # Exclude the generic image and update payload because they are needed for generating other formats
            if [ "${FLAGS_only_store_compressed}" -eq "${FLAGS_TRUE}" ] &&
               [ "${filename##*/}" != "flatcar_production_image.bin" ] &&
               [ "${filename##*/}" != "flatcar_production_update.bin" ] &&
               ! echo "${FORMATS[@]}" | grep -q "none"; then
                info "Removing ${filename}"
                rm "${filename}"
            else
                info "Keeping ${filename}"
            fi
        fi
    done
}
