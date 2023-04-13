# Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Shell library for functions and initialization private to
# build_image, and not specific to any particular kind of image.
#
# TODO(jrbarnette):  There's nothing holding this code together in
# one file aside from its lack of anywhere else to go.  Probably,
# this file should get broken up or otherwise reorganized.

# Use canonical path since some tools (e.g. mount) do not like symlinks.
# Append build attempt to output directory.
if [ -z "${FLAGS_version}" ]; then
  IMAGE_SUBDIR="${FLAGS_group}-${FLATCAR_VERSION}-a${FLAGS_build_attempt}"
else
  IMAGE_SUBDIR="${FLAGS_group}-${FLAGS_version}"
fi
BUILD_DIR="${FLAGS_output_root}/${BOARD}/${IMAGE_SUBDIR}"
OUTSIDE_OUTPUT_DIR="../build/images/${BOARD}/${IMAGE_SUBDIR}"

set_build_symlinks() {
    local build=$(basename ${BUILD_DIR})
    local link
    for link in "$@"; do
        local path="${FLAGS_output_root}/${BOARD}/${link}"
        ln -sfT "${build}" "${path}"
    done
}

cleanup_mounts() {
  info "Cleaning up mounts"
  "${BUILD_LIBRARY_DIR}/disk_util" umount "$1" || true
  rmdir "${1}" || true
}

delete_prompt() {
  echo "An error occurred in your build so your latest output directory" \
    "is invalid."

  # Only prompt if both stdin and stdout are a tty. If either is not a tty,
  # then the user may not be present, so we shouldn't bother prompting.
  if [ -t 0 -a -t 1 ]; then
    read -p "Would you like to delete the output directory (y/N)? " SURE
    SURE="${SURE:0:1}" # Get just the first character.
  else
    SURE="y"
    echo "Running in non-interactive mode so deleting output directory."
  fi
  if [ "${SURE}" == "y" ] ; then
    sudo rm -rf "${BUILD_DIR}"
    echo "Deleted ${BUILD_DIR}"
  else
    echo "Not deleting ${BUILD_DIR}."
  fi
}

extract_update() {
  local image_name="$1"
  local disk_layout="$2"
  local update_path="${BUILD_DIR}/${image_name%_image.bin}_update.bin"
  local digest_path="${update_path}.DIGESTS"

  "${BUILD_LIBRARY_DIR}/disk_util" --disk_layout="${disk_layout}" \
    extract "${BUILD_DIR}/${image_name}" "USR-A" "${update_path}"

  # Compress image
  files_to_evaluate+=( "${update_path}" )
  declare -a compressed_images
  declare -a extra_files
  compress_disk_images files_to_evaluate compressed_images extra_files

  # Upload compressed image
  upload_image -d "${digest_path}" "${compressed_images[@]}" "${extra_files[@]}"

  # Upload legacy digests
  upload_legacy_digests "${digest_path}" compressed_images

  # For production as well as dev builds we generate a dev-key-signed update
  # payload for running tests (the signature won't be accepted by production systems).
  local update_test="${BUILD_DIR}/flatcar_test_update.gz"
  delta_generator \
      -private_key "/usr/share/update_engine/update-payload-key.key.pem" \
      -new_image "${update_path}" \
      -new_kernel "${BUILD_DIR}/${image_name%.bin}.vmlinuz" \
      -out_file "${update_test}"

  upload_image "${update_test}"
}

zip_update_tools() {
  # There isn't a 'dev' variant of this zip, so always call it production.
  local update_zip="flatcar_production_update.zip"

  info "Generating update tools zip"
  # Make sure some vars this script needs are exported
  export REPO_MANIFESTS_DIR SCRIPTS_DIR
  "${BUILD_LIBRARY_DIR}/generate_au_zip.py" \
    --arch "$(get_sdk_arch)" --output-dir "${BUILD_DIR}" --zip-name "${update_zip}"

  upload_image "${BUILD_DIR}/${update_zip}"
}

generate_update() {
  local image_name="$1"
  local disk_layout="$2"
  local image_kernel="${BUILD_DIR}/${image_name%.bin}.vmlinuz"
  local update_prefix="${image_name%_image.bin}_update"
  local update="${BUILD_DIR}/${update_prefix}"
  local devkey="/usr/share/update_engine/update-payload-key.key.pem"

  echo "Generating update payload, signed with a dev key"
  "${BUILD_LIBRARY_DIR}/disk_util" --disk_layout="${disk_layout}" \
    extract "${BUILD_DIR}/${image_name}" "USR-A" "${update}.bin"
  delta_generator \
      -private_key "${devkey}" \
      -new_image "${update}.bin" \
      -new_kernel "${image_kernel}" \
      -out_file "${update}.gz"

  # Compress image
  declare -a files_to_evaluate
  declare -a compressed_images
  declare -a extra_files
  files_to_evaluate+=( "${update}.bin" )
  compress_disk_images files_to_evaluate compressed_images extra_files

  # Upload images
  upload_image -d "${update}.DIGESTS" "${update}".{gz,zip} "${compressed_images[@]}" "${extra_files[@]}"

  # Upload legacy digests
  upload_legacy_digests "${update}.DIGESTS" compressed_images
}

# ldconfig cannot generate caches for non-native arches.
# Use qemu & the native ldconfig to work around that.
# http://code.google.com/p/chromium/issues/detail?id=378377
run_ldconfig() {
  local root_fs_dir=$1
  case ${ARCH} in
  arm64)
    sudo qemu-aarch64 "${root_fs_dir}"/usr/sbin/ldconfig -r "${root_fs_dir}";;
  x86|amd64)
    sudo ldconfig -r "${root_fs_dir}";;
  *)
    die "Unable to run ldconfig for ARCH ${ARCH}"
  esac
}

run_localedef() {
  local root_fs_dir="$1" loader=()
  case ${ARCH} in
  arm64)
    loader=( qemu-aarch64 -L "${root_fs_dir}" );;
  amd64)
    loader=( "${root_fs_dir}/usr/lib64/ld-linux-x86-64.so.2" \
               --library-path "${root_fs_dir}/usr/lib64" );;
  *)
    die "Unable to run localedev for ARCH ${ARCH}";;
  esac
  info "Generating C.UTF-8 locale..."
  local i18n="${root_fs_dir}/usr/share/i18n"
  # localedef will silently fall back to /usr/share/i18n if missing so
  # check that the paths we want are available first.
  [[ -f "${i18n}/charmaps/UTF-8.gz" ]] || die
  [[ -f "${i18n}/locales/C" ]] || die
  sudo I18NPATH="${i18n}" "${loader[@]}" "${root_fs_dir}/usr/bin/localedef" \
      --prefix="${root_fs_dir}" --charmap=UTF-8 --inputfile=C C.UTF-8
}

# Basic command to emerge binary packages into the target image.
# Arguments to this command are passed as addition options/arguments
# to the basic emerge command.
emerge_to_image() {
  local root_fs_dir="$1"; shift

  if [[ ${FLAGS_getbinpkg} -eq ${FLAGS_TRUE} ]]; then
    set -- --getbinpkg "$@"
  fi

  sudo -E ROOT="${root_fs_dir}" \
      PORTAGE_CONFIGROOT="${BUILD_DIR}"/configroot \
      emerge --root-deps=rdeps --usepkgonly --jobs="${NUM_JOBS}" -v "$@"

  # Shortcut if this was just baselayout
  [[ "$*" == *sys-apps/baselayout ]] && return

  # Make sure profile.env has been generated
  sudo -E ROOT="${root_fs_dir}" env-update --no-ldconfig

  fixup_liblto_softlinks "$root_fs_dir"

  # TODO(marineam): just call ${BUILD_LIBRARY_DIR}/check_root directly once
  # all tests are fatal, for now let the old function skip soname errors.
  ROOT="${root_fs_dir}" PORTAGE_CONFIGROOT="${BUILD_DIR}"/configroot \
      test_image_content "${root_fs_dir}"
}

# emerge_to_image without a rootfs check; you should use emerge_to_image unless
# here's a good reason not to.
emerge_to_image_unchecked() {
  local root_fs_dir="$1"; shift

  if [[ ${FLAGS_getbinpkg} -eq ${FLAGS_TRUE} ]]; then
    set -- --getbinpkg "$@"
  fi

  sudo -E ROOT="${root_fs_dir}" \
      PORTAGE_CONFIGROOT="${BUILD_DIR}"/configroot \
      emerge --root-deps=rdeps --usepkgonly --jobs="${NUM_JOBS}" -v "$@"

  # Shortcut if this was just baselayout
  [[ "$*" == *sys-apps/baselayout ]] && return

  # Make sure profile.env has been generated
  sudo -E ROOT="${root_fs_dir}" env-update --no-ldconfig
}

# Switch to the dev or prod sub-profile
set_image_profile() {
  local suffix="$1"
  local profile="${BUILD_DIR}/configroot/etc/portage/make.profile"
  if [[ ! -d "${profile}/${suffix}" ]]; then
      die "Not a valid profile: ${profile}/${suffix}"
  fi
  local realpath=$(readlink -f "${profile}/${suffix}")
  ln -snf "${realpath}" "${profile}"
}

# Usage: systemd_enable /root default.target something.service
# Or: systemd_enable /root default.target some@.service some@thing.service
systemd_enable() {
  local root_fs_dir="$1"
  local target="$2"
  local unit_file="$3"
  local unit_alias="${4:-$3}"
  local wants_dir="${root_fs_dir}/usr/lib/systemd/system/${target}.wants"

  sudo mkdir -p "${wants_dir}"
  sudo ln -sf "../${unit_file}" "${wants_dir}/${unit_alias}"
}

# Generate a ls-like listing of a directory tree.
# The ugly printf is used to predictable time format and size in bytes.
write_contents() {
    info "Writing ${2##*/}"
    pushd "$1" >/dev/null
    # %M - file permissions
    # %n - number of hard links to file
    # %u - file's user name
    # %g - file's group name
    # %s - size in bytes
    # %Tx - modification time (Y - year, m - month, d - day, H - hours, M - minutes)
    # %P - file's path
    # %l - symlink target (empty if not a symlink)
    sudo TZ=UTC find -printf \
        '%M %2n %-7u %-7g %7s %TY-%Tm-%Td %TH:%TM ./%P -> %l\n' \
        | sed -e 's/ -> $//' > "$2"
    popd >/dev/null
}

# Generate a listing that can be used by other tools to analyze
# image/file size changes.
write_contents_with_technical_details() {
    info "Writing ${2##*/}"
    pushd "$1" >/dev/null
    # %M - file permissions
    # %D - ID of a device where file resides
    # %i - inode number
    # %n - number of hard links to file
    # %s - size in bytes
    # %P - file's path
    sudo find -printf \
        '%M %D %i %n %s ./%P\n' > "$2"
    popd >/dev/null
}

# Generate a report like the following:
#
# File    Size  Used Avail Use% Type
# /boot   127M   62M   65M  50% vfat
# /usr    983M  721M  212M  78% ext2
# /       6,0G   13M  5,6G   1% ext4
# SUM     7,0G  796M  5,9G  12% -
write_disk_space_usage() {
    info "Writing ${2##*/}"
    pushd "${1}" >/dev/null
    # The sed's first command turns './<path>' into '/<path> ', second
    # command replaces '- ' with 'SUM' for the total row. All this to
    # keep the numbers neatly aligned in columns.
    sudo df \
         --human-readable \
         --total \
         --output='file,size,used,avail,pcent,fstype' \
         ./boot ./usr ./ | \
        sed \
            -e 's#^\.\(/[^ ]*\)#\1 #' \
            -e 's/^-  /SUM/' >"${2}"
    popd >/dev/null
}

# "equery list" a potentially uninstalled board package
query_available_package() {
    local pkg="$1"
    local format="${2:-\$cpv::\$repo}"
    # Ignore masked versions. Assumes that sort --version-sort uses the
    # same ordering as Portage.
    equery-${BOARD} --no-color list -po --format "\$mask|$format" "$pkg" | \
            grep -E '^ +\|' | \
            cut -f2- -d\| | \
            sort --version-sort | \
            tail -n 1
}

# Generate a list of packages installed in an image.
# Usage: image_packages /image/root
image_packages() {
    local profile="${BUILD_DIR}/configroot/etc/portage/profile"    
    ROOT="$1" PORTAGE_CONFIGROOT="${BUILD_DIR}"/configroot \
        equery --no-color list --format '$cpv::$repo' '*'

    # We also want to list packages that only exist in the initramfs.
    # Approximate this by listing build dependencies of coreos-kernel that
    # are specified with the "=" slot operator, excluding those already
    # reported above.
    local kernel_pkg=$(ROOT="$1" PORTAGE_CONFIGROOT="${BUILD_DIR}"/configroot \
        equery --no-color list --format '$cpv' sys-kernel/coreos-kernel)
    # OEM ACIs have no kernel package.
    if [[ -n "${kernel_pkg}" ]]; then
        local depend_path="$1/var/db/pkg/$kernel_pkg/DEPEND"
        local pkg
        for pkg in $(awk 'BEGIN {RS=" "} /=$/ {print}' "$depend_path"); do
            if ! ROOT="$1" PORTAGE_CONFIGROOT="${BUILD_DIR}"/configroot \
                    equery -q list "$pkg" >/dev/null ; then
                query_available_package "$pkg"
            fi
        done
    fi

    # In production images GCC libraries are extracted manually.
    if [[ -f "${profile}/package.provided" ]]; then
        local pkg
        while read pkg; do
            query_available_package "${pkg}"
        done < "${profile}/package.provided"
    fi

    # Include source packages of all torcx images installed on disk.
    [ -z "${FLAGS_torcx_manifest}" ] ||
    torcx_manifest::sources_on_disk "${FLAGS_torcx_manifest}" |
    while read pkg ; do query_available_package "${pkg}" ; done
}

# Generate a list of installed packages in the format:
#   sys-apps/systemd-212-r8::coreos
write_packages() {
    info "Writing ${2##*/}"
    image_packages "$1" | sort > "$2"
}

# Get metadata $key for package $pkg installed under $prefix
# The metadata is either read from the portage db folder or
# via a portageq-BOARD invocation. In cases where SRC_URI is
# not used for the package, fallback mechanisms are used to find
# the source URL. Mirror names are replaced with the mirror URLs.
get_metadata() {
    local prefix="$1"
    local pkg="$2"
    local key="$3"
    local path="${prefix}/var/db/pkg/${pkg%%:*}/${key}"
    local val
    if [[ -f "$path" ]]; then
        val="$(< $path)"
    else
        # The package is not installed in $prefix or $key not exposed as file,
        # so get the value from its ebuild
        val=$(portageq-${BOARD} metadata "${BOARD_ROOT}" ebuild \
                    "${pkg%%:*}" "${key}" 2>/dev/null ||:)
    fi
    # The value that portageq reports is not a valid URL because it uses a special mirror format.
    # Also the value can be empty and fallback methods have to be used.
    if [ "${key}" = "SRC_URI" ]; then
        local package_name="$(echo "${pkg%%:*}" | cut -d / -f 2)"
        local ebuild_path="${prefix}/var/db/pkg/${pkg%%:*}/${package_name}.ebuild"
        # SRC_URI is empty for the special github.com/flatcar projects
        if [ -z "${val}" ]; then
            # The grep invocation gives errors when the ebuild file is not present.
            # This can happen when the binary packages from ./build_packages are outdated.
            val="$(grep "CROS_WORKON_PROJECT=" "${ebuild_path}" | cut -d '"' -f 2)"
            if [ -n "${val}" ]; then
                val="https://github.com/${val}"
                # All github.com/flatcar projects specify their commit
                local commit=""
                commit="$(grep "CROS_WORKON_COMMIT=" "${ebuild_path}" | cut -d '"' -f 2)"
                if [ -n "${commit}" ]; then
                    val="${val}/commit/${commit}"
                fi
            fi
        fi
        # During development "portageq-BOARD metadata ... ebuild ..." may result in the package not being found, fall back to a parameterized URL
        if [ -z "${val}" ]; then
            # Do not attempt to postprocess by resolving ${P} and friends because it does not affect production images
            val="$(cat "${ebuild_path}" | tr '\n' ' ' | grep -P -o 'SRC_URI=".*?"' | cut -d '"' -f 2)"
        fi
        # Some packages use nothing from the above but EGIT_REPO_URI (currently only app-crypt/go-tspi)
        if [ -z "${val}" ]; then
            val="$(grep "EGIT_REPO_URI=" "${ebuild_path}" | cut -d '"' -f 2)"
        fi
        # Replace all mirror://MIRRORNAME/ parts with the actual URL prefix of the mirror
        new_val=""
        for v in ${val}; do
            local mirror="$(echo "${v}" | grep mirror:// | cut -d '/' -f 3)"
            if [ -n "${mirror}" ]; then
                # Take only first mirror, those not working should be removed
                local location="$(grep "^${mirror}"$'\t' /var/gentoo/repos/gentoo/profiles/thirdpartymirrors | cut -d $'\t' -f 2- | cut -d ' ' -f 1 | tr -d $'\t')"
                v="$(echo "${v}" | sed "s#mirror://${mirror}/#${location}#g")"
            fi
            new_val+="${v} "
        done
        val="${new_val}"
    fi
    echo "${val}"
}

# Generate a list of packages w/ their licenses in the format:
#   [
#     {
#       "project": "sys-apps/systemd-212-r8::coreos",
#       "licenses": ["GPL-2", "LGPL-2.1", "MIT", "public-domain"],
#       "description": "System and service manager for Linux",
#       "homepage": "https://www.freedesktop.org/wiki/Software/systemd",
#       "source": "https://github.com/systemd/systemd ",
#       "files": "somefile 63a5736879fa647ac5a8d5317e7cb8b0\nsome -> link\n"
#     }
#   ]
write_licenses() {
    info "Writing ${2##*/}"
    echo -n "[" > "$2"

    local pkg pkg_sep
    for pkg in $(image_packages "$1" | sort); do
        # Ignore certain categories of packages since they aren't licensed
        case "${pkg%%/*}" in
            'virtual'|'acct-group'|'acct-user')
                continue
                ;;
        esac

        local lic_str="$(get_metadata "$1" "${pkg}" LICENSE)"
        if [[ -z "$lic_str" ]]; then
                warn "No license found for ${pkg}"
                continue
        fi

        [[ -n $pkg_sep ]] && echo ","
        [[ -z $pkg_sep ]] && echo
        pkg_sep="true"

        # Build a list of the required licenses vs the one-of licenses
        # For example:
        #   GPL-3+ LGPL-3+ || ( GPL-3+ libgcc libstdc++ ) FDL-1.3+
        #   required: GPL-3+ LGPL-3+ FDL-1.3+
        #   one-of: GPL-3+ libgcc libstdc++
        local req_lics=($(sed 's/|| ([^)]*)//' <<< $lic_str))
        local opt_lics=($(sed 's/.*|| (\([^)]*\)).*/\1/' <<< $lic_str))

        # Pick one of the one-of licenses, preferring a GPL license. Otherwise,
        # pick the first.
        local opt_lic=""
        local lic
        for lic in ${opt_lics[*]}; do
            if [[ $lic =~ "GPL" ]]; then
                opt_lic=$lic;
                break
            fi;
        done
        if [[ -z $opt_lic ]]; then
            opt_lic=${opt_lics[0]}
        fi

        # Remove duplicate licenses
        local lics=$(tr ' ' '\n' <<< "${req_lics[*]} ${opt_lic}" | sort --unique | tr '\n' ' ')

        local homepage="$(get_metadata "$1" "${pkg}" HOMEPAGE)"
        local description="$(get_metadata "$1" "${pkg}" DESCRIPTION)"
        local src_uri="$(get_metadata "$1" "${pkg}" SRC_URI)"
        # Filter out directories, cut type marker, cut timestamp, quote "\", and convert line breaks to "\n"
        # Filter any unicode characters "rev" doesn't handle (currently some ca-certificates files) and
        # replace them with a "?" so that the files can still be opened thanks to shell file name expansion
        local files="$(get_metadata "$1" "${pkg}" CONTENTS | grep -v '^dir ' | \
            cut -d ' ' -f 2- | tr -c '[[:print:][:cntrl:]]' '?' | rev | cut -d ' ' -f 2- | rev | \
            sed 's#\\#\\\\#g' | tr '\n' '*' | sed 's/*/\\n/g')"

        echo -n "  {\"project\": \"${pkg}\", \"licenses\": ["

        local lic_sep=""
        for lic in ${lics[*]}; do
            [[ -n $lic_sep ]] && echo -n ", "
            lic_sep="true"

            echo -n "\"${lic}\""
        done

        echo -n "], \"description\": \"${description}\", \"homepage\": \"${homepage}\", \
            \"source\": \"${src_uri}\", \"files\": \"${files}\"}"
    done >> "$2"

    echo -e "\n]" >> "$2"
    # Pretty print the JSON file
    mv "$2" "$2".tmp
    jq . "$2".tmp > "$2"
    rm "$2".tmp
}

# Include the license JSON and all licenses in the rootfs with a small INFO file about usage and other URLs.
insert_licenses() {
    local json_input="$1"
    local root_fs_dir="$2"
    sudo mkdir -p "${root_fs_dir}"/usr/share/licenses/common
    sudo_clobber "${root_fs_dir}"/usr/share/licenses/INFO << "EOF"
Flatcar Container Linux distributes software from various projects.
The licenses.json.bz2 file contains the list of projects with their licenses, how to obtain the source code,
and which binary files in Flatcar Container Linux were created from it.
You can read it with "less licenses.json.bz2" or convert it to a text format with
bzcat licenses.json.bz2 | jq -r '.[] | "\(.project):\nDescription: \(.description)\nLicenses: \(.licenses)\nHomepage: \(.homepage)\nSource code: \(.source)\nFiles:\n\(.files)\n"'
The license texts are available under /usr/share/licenses/common/ and can be read with "less NAME.gz".
Build system files and patches used to build these projects are located at:
https://github.com/flatcar/scripts/
Information on how to build Flatcar Container Linux can be found under:
https://www.flatcar.org/docs/latest/reference/developer-guides/sdk-modifying-flatcar/
EOF
    sudo cp "${json_input}" "${root_fs_dir}"/usr/share/licenses/licenses.json
    # Compress the file from 2.1 MB to 0.39 MB
    sudo lbzip2 -9 "${root_fs_dir}"/usr/share/licenses/licenses.json
    # Copy all needed licenses to a "common" subdirectory and compress them
    local license_list # define before assignment because it would mask any error
    license_list="$(jq -r '.[] | "\(.licenses | .[])"' "${json_input}" | sort | uniq)"
    local license_dirs=(
        "/mnt/host/source/src/third_party/coreos-overlay/licenses/"
        "/mnt/host/source/src/third_party/portage-stable/"
        "/var/gentoo/repos/gentoo/licenses/"
        "none"
    )
    for license_file in ${license_list}; do
        for license_dir in ${license_dirs[*]}; do
            if [ "${license_dir}" = "none" ]; then
                warn "The license file \"${license_file}\" was not found"
            elif [ -f "${license_dir}${license_file}" ]; then
                sudo cp "${license_dir}${license_file}" "${root_fs_dir}"/usr/share/licenses/common/
                break
            fi
        done
    done
    # Compress the licenses just with gzip because there is no big difference as they are single files
    sudo gzip -9 "${root_fs_dir}"/usr/share/licenses/common/*
}

# Add an entry to the image's package.provided
package_provided() {
    local p profile="${BUILD_DIR}/configroot/etc/portage/profile"    
    for p in "$@"; do
        info "Writing $p to package.provided and soname.provided"
        echo "$p" >> "${profile}/package.provided"
	pkg_provides binary "$p" >> "${profile}/soname.provided"
    done
}

assert_image_size() {
  local disk_img="$1"
  local disk_type="$2"

  local size
  size=$(qemu-img info -f "${disk_type}" --output json "${disk_img}" | \
    jq --raw-output '.["virtual-size"]' ; exit ${PIPESTATUS[0]})
  if [[ $? -ne 0 ]]; then
    die_notrace "assert failed: could not read image size"
  fi

  MiB=$((1024*1024))
  if [[ $(($size % $MiB)) -ne 0 ]]; then
    die_notrace "assert failed: image must be a multiple of 1 MiB ($size B)"
  fi
}

start_image() {
  local image_name="$1"
  local disk_layout="$2"
  local root_fs_dir="$3"
  local update_group="$4"

  local disk_img="${BUILD_DIR}/${image_name}"

  mkdir -p "${BUILD_DIR}"/configroot/etc/portage/profile
  ln -s "${BOARD_ROOT}"/etc/portage/make.* \
      "${BOARD_ROOT}"/etc/portage/package.* \
      "${BOARD_ROOT}"/etc/portage/repos.conf \
      "${BUILD_DIR}"/configroot/etc/portage/

  info "Using image type ${disk_layout}"
  "${BUILD_LIBRARY_DIR}/disk_util" --disk_layout="${disk_layout}" \
      format "${disk_img}"

  assert_image_size "${disk_img}" raw

  "${BUILD_LIBRARY_DIR}/disk_util" --disk_layout="${disk_layout}" \
      mount --writable_verity "${disk_img}" "${root_fs_dir}"
  trap "cleanup_mounts '${root_fs_dir}' && delete_prompt" EXIT

  # First thing first, install baselayout to create a working filesystem.
  emerge_to_image "${root_fs_dir}" --nodeps --oneshot sys-apps/baselayout

  # FIXME(marineam): Work around glibc setting EROOT=$ROOT
  # https://bugs.gentoo.org/show_bug.cgi?id=473728#c12
  sudo mkdir -p "${root_fs_dir}/etc/ld.so.conf.d"

  # Set /etc/lsb-release on the image.
  "${BUILD_LIBRARY_DIR}/set_lsb_release" \
    --root="${root_fs_dir}" \
    --group="${update_group}" \
    --board="${BOARD}"
}

finish_image() {
  local image_name="$1"
  local disk_layout="$2"
  local root_fs_dir="$3"
  local image_contents="$4"
  local image_contents_wtd="$5"
  local image_kernel="$6"
  local pcr_policy="$7"
  local image_grub="$8"
  local image_shim="$9"
  local image_kconfig="${10}"
  local image_initrd_contents="${11}"
  local image_initrd_contents_wtd="${12}"
  local image_disk_space_usage="${13}"

  local install_grub=0
  local disk_img="${BUILD_DIR}/${image_name}"

  # Copy in packages from the torcx store that are marked as being on disk
  if [ -n "${FLAGS_torcx_manifest}" ]; then
    for pkg in $(torcx_manifest::get_pkg_names "${FLAGS_torcx_manifest}"); do
      local default_version="$(torcx_manifest::default_version "${FLAGS_torcx_manifest}" "${pkg}")"
      for version in $(torcx_manifest::get_versions "${FLAGS_torcx_manifest}" "${pkg}"); do
        local on_disk_path="$(torcx_manifest::local_store_path "${FLAGS_torcx_manifest}" "${pkg}" "${version}")"
        if [[ -n "${on_disk_path}" ]]; then
          local casDigest="$(torcx_manifest::get_digest "${FLAGS_torcx_manifest}" "${pkg}" "${version}")"
          sudo cp "${FLAGS_torcx_root}/pkgs/${BOARD}/${pkg}/${casDigest}/${pkg}:${version}.torcx.tgz" \
            "${root_fs_dir}${on_disk_path}"

          if [[ "${version}" == "${default_version}" ]]; then
            # Create the default symlink for this package
            sudo ln -fns "${on_disk_path##*/}" \
              "${root_fs_dir}/${on_disk_path%/*}/${pkg}:com.coreos.cl.torcx.tgz"
          fi
        fi
      done
    done
  fi

  # Only enable rootfs verification on prod builds.
  local disable_read_write="${FLAGS_FALSE}"
  if [[ "${IMAGE_BUILD_TYPE}" == "prod" ]]; then
    disable_read_write="${FLAGS_enable_rootfs_verification}"
  fi

  # Only enable rootfs verification on supported boards.
  case "${FLAGS_board}" in
    amd64-usr) verity_offset=64 ;;
    arm64-usr) verity_offset=512 ;;
    *) disable_read_write=${FLAGS_FALSE} ;;
  esac

  # Copy kernel to the /boot partition to support dm-verity boots by embedding
  # the hash of the /usr partition into the kernel.
  # Remove the kernel from the /usr partition to save space.
  sudo mkdir -p "${root_fs_dir}/boot/flatcar"
  sudo cp "${root_fs_dir}/usr/boot/vmlinuz" \
       "${root_fs_dir}/boot/flatcar/vmlinuz-a"
  sudo rm "${root_fs_dir}/usr/boot/vmlinuz"*

  # Record directories installed to the state partition.
  # Explicitly ignore entries covered by existing configs.
  local tmp_ignore=$(awk '/^[dDfFL]/ {print "--ignore=" $2}' \
      "${root_fs_dir}"/usr/lib/tmpfiles.d/*.conf)
  sudo "${BUILD_LIBRARY_DIR}/gen_tmpfiles.py" --root="${root_fs_dir}" \
      --output="${root_fs_dir}/usr/lib/tmpfiles.d/base_image_var.conf" \
      ${tmp_ignore} "${root_fs_dir}/var"
  sudo "${BUILD_LIBRARY_DIR}/gen_tmpfiles.py" --root="${root_fs_dir}" \
      --output="${root_fs_dir}/usr/lib/tmpfiles.d/base_image_etc.conf" \
      ${tmp_ignore} "${root_fs_dir}/etc"

  # Only configure bootloaders if there is a boot partition
  if mountpoint -q "${root_fs_dir}"/boot; then
    install_grub=1
    ${BUILD_LIBRARY_DIR}/configure_bootloaders.sh \
      --boot_dir="${root_fs_dir}"/usr/boot

    # Create first-boot flag for grub and Ignition
    info "Writing first-boot flag"
    sudo_clobber "${root_fs_dir}/boot/flatcar/first_boot" <<EOF
If this file exists, Ignition will run and then delete the file.
EOF
  fi

  if [[ -n "${FLAGS_developer_data}" ]]; then
    local data_path="/usr/share/flatcar/developer_data"
    local unit_path="usr-share-flatcar-developer_data"
    sudo cp "${FLAGS_developer_data}" "${root_fs_dir}/${data_path}"
    systemd_enable "${root_fs_dir}" system-config.target \
        "system-cloudinit@.service" "system-cloudinit@${unit_path}.service"
  fi

  if [[ -n "${image_kconfig}" ]]; then
    cp "${root_fs_dir}/usr/boot/config" \
        "${BUILD_DIR}/${image_kconfig}"
  fi

  # Zero all fs free space to make it more compressible so auto-update
  # payloads become smaller, not fatal since it won't work on linux < 3.2
  sudo fstrim "${root_fs_dir}" || true
  if mountpoint -q "${root_fs_dir}/usr"; then
    sudo fstrim "${root_fs_dir}/usr" || true
  fi

  # Build the selinux policy
  if pkg_use_enabled coreos-base/coreos selinux; then
      sudo chroot "${root_fs_dir}" bash -c "cd /usr/share/selinux/mcs && semodule -s mcs -i *.pp"
  fi

  # Make the filesystem un-mountable as read-write and setup verity.
  if [[ ${disable_read_write} -eq ${FLAGS_TRUE} ]]; then
    # Unmount /usr partition
    sudo umount --recursive "${root_fs_dir}/usr" || exit 1

    "${BUILD_LIBRARY_DIR}/disk_util" --disk_layout="${disk_layout}" verity \
        --root_hash="${BUILD_DIR}/${image_name%.bin}_verity.txt" \
        "${BUILD_DIR}/${image_name}"

    # Magic alert!  Root hash injection works by writing the hash value to a
    # known unused SHA256-sized location in the kernel image.
    # For amd64 the rdev error message is used.
    # For arm64 an area between the EFI headers and the kernel text is used.
    # Our modified GRUB extracts the hash and adds it to the cmdline.
    printf %s "$(cat ${BUILD_DIR}/${image_name%.bin}_verity.txt)" | \
        sudo dd of="${root_fs_dir}/boot/flatcar/vmlinuz-a" conv=notrunc \
        seek=${verity_offset} count=64 bs=1 status=none
  fi

  # Sign the kernel after /usr is in a consistent state and verity is calculated
  if [[ ${COREOS_OFFICIAL:-0} -ne 1 ]]; then
      sudo sbsign --key /usr/share/sb_keys/DB.key \
	   --cert /usr/share/sb_keys/DB.crt \
	   "${root_fs_dir}/boot/flatcar/vmlinuz-a"
      sudo mv "${root_fs_dir}/boot/flatcar/vmlinuz-a.signed" \
	   "${root_fs_dir}/boot/flatcar/vmlinuz-a"
  fi

  if [[ -n "${image_kernel}" ]]; then
    # copying kernel from vfat so ignore the permissions
    cp --no-preserve=mode \
        "${root_fs_dir}/boot/flatcar/vmlinuz-a" \
        "${BUILD_DIR}/${image_kernel}"
  fi

  if [[ -n "${pcr_policy}" ]]; then
    mkdir -p "${BUILD_DIR}/pcrs"
    ${BUILD_LIBRARY_DIR}/generate_kernel_hash.py \
        "${root_fs_dir}/boot/flatcar/vmlinuz-a" ${FLATCAR_VERSION} \
        >"${BUILD_DIR}/pcrs/kernel.config"
  fi

  rm -rf "${BUILD_DIR}"/configroot
  cleanup_mounts "${root_fs_dir}"
  trap - EXIT

  # This script must mount the ESP partition differently, so run it after unmount
  if [[ "${install_grub}" -eq 1 ]]; then
    local target
    local target_list="i386-pc x86_64-efi x86_64-xen"
    if [[ ${BOARD} == "arm64-usr" ]]; then
      target_list="arm64-efi"
    fi
    local grub_args=()
    if [[ ${disable_read_write} -eq ${FLAGS_TRUE} ]]; then
      grub_args+=(--verity)
    else
      grub_args+=(--noverity)
    fi
    if [[ -n "${image_grub}" && -n "${image_shim}" ]]; then
      grub_args+=(
        --copy_efi_grub="${BUILD_DIR}/${image_grub}"
        --copy_shim="${BUILD_DIR}/${image_shim}"
      )
    fi
    for target in ${target_list}; do
      ${BUILD_LIBRARY_DIR}/grub_install.sh \
          --board="${BOARD}" \
          --target="${target}" \
          --disk_image="${disk_img}" \
          "${grub_args[@]}"
    done
  fi

  if [[ -n "${pcr_policy}" ]]; then
    ${BUILD_LIBRARY_DIR}/generate_grub_hashes.py \
        "${disk_img}" /usr/lib/grub/ "${BUILD_DIR}/pcrs" ${FLATCAR_VERSION}

    info "Generating $pcr_policy"
    pushd "${BUILD_DIR}" >/dev/null
    zip --quiet -r -9 "${BUILD_DIR}/${pcr_policy}" pcrs
    popd >/dev/null
    rm -rf "${BUILD_DIR}/pcrs"
  fi

  # Mount the final image again, as readonly, to generate some reports.
  "${BUILD_LIBRARY_DIR}/disk_util" --disk_layout="${disk_layout}" \
      mount --read_only "${disk_img}" "${root_fs_dir}"
  trap "cleanup_mounts '${root_fs_dir}'" EXIT

  write_contents "${root_fs_dir}" "${BUILD_DIR}/${image_contents}"
  write_contents_with_technical_details "${root_fs_dir}" "${BUILD_DIR}/${image_contents_wtd}"

  if [[ -n "${image_initrd_contents}" ]] || [[ -n "${image_initrd_contents_wtd}" ]]; then
      "${BUILD_LIBRARY_DIR}/extract-initramfs-from-vmlinuz.sh" "${root_fs_dir}/boot/flatcar/vmlinuz-a" "${BUILD_DIR}/tmp_initrd_contents"
      if [[ -n "${image_initrd_contents}" ]]; then
          write_contents "${BUILD_DIR}/tmp_initrd_contents" "${BUILD_DIR}/${image_initrd_contents}"
      fi

      if [[ -n "${image_initrd_contents_wtd}" ]]; then
          write_contents_with_technical_details "${BUILD_DIR}/tmp_initrd_contents" "${BUILD_DIR}/${image_initrd_contents_wtd}"
      fi
      rm -rf "${BUILD_DIR}/tmp_initrd_contents"
  fi

  if [[ -n "${image_disk_space_usage}" ]]; then
      write_disk_space_usage "${root_fs_dir}" "${BUILD_DIR}/${image_disk_space_usage}"
  fi

  cleanup_mounts "${root_fs_dir}"
  trap - EXIT
}
