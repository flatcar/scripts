# Copyright (c) 2013 The CoreOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Format options. Each variable uses the form IMG_<type>_<opt>.
# Default values use the format IMG_DEFAULT_<opt>.

VALID_IMG_TYPES=(
    akamai
    ami
    ami_vmdk
    azure
    cloudsigma
    cloudstack
    cloudstack_vhd
    digitalocean
    exoscale
    gce
    hetzner
    hyperv
    hyperv_vhdx
    iso
    kubevirt
    openstack
    openstack_mini
    packet
    parallels
    proxmoxve
    pxe
    qemu_uefi
    rackspace
    rackspace_onmetal
    rackspace_vhd
    scaleway
    stackit
    vagrant
    vagrant_parallels
    vagrant_virtualbox
    vagrant_vmware_fusion
    virtualbox
    vmware
    vmware_insecure
    vmware_ova
    vmware_raw
    xen
)

#list of oem package names, minus the oem- prefix
VALID_OEM_PACKAGES=(
    akamai
    azure
    cloudsigma
    cloudstack
    digitalocean
    exoscale
    gce
    hetzner
    hyperv
    kubevirt
    openstack
    packet
    proxmoxve
    qemu
    rackspace
    rackspace-onmetal
    scaleway
    stackit
    vagrant
    vagrant-key
    vagrant-virtualbox
    virtualbox
    vmware
)

# Set at runtime to one of the above types
VM_IMG_TYPE=DEFAULT

# Set at runtime to the source and destination image paths
VM_SRC_IMG=
VM_SRC_SYSEXT_IMG=
VM_TMP_IMG=
VM_TMP_DIR=
VM_TMP_ROOT=
VM_DST_IMG=
VM_README=
VM_NAME=
VM_GROUP=

# Contains a list of all generated files
VM_GENERATED_FILES=()

## DEFAULT
# If set to 0 then a partition skeleton won't be laid out on VM_TMP_IMG
IMG_DEFAULT_PARTITIONED_IMG=1

# If set install the given package name to the OEM partition
IMG_DEFAULT_OEM_PACKAGE=

# Forced OEM package name overriding what may be in the format
IMG_FORCE_OEM_PACKAGE=

# USE flags for the OEM package
IMG_DEFAULT_OEM_USE=

# Forced USE flags for the OEM package
IMG_FORCE_OEM_USE=

# If set install the given package name to the OEM sysext image
IMG_DEFAULT_OEM_SYSEXT=

# Forced OEM package name overriding what may be in the format
IMG_FORCE_OEM_SYSEXT=

# Hook to do any final tweaks or grab data while fs is mounted.
IMG_DEFAULT_FS_HOOK=

# Name of the target image format.
# May be raw, qcow2 (qemu), or vmdk (vmware, virtualbox)
IMG_DEFAULT_DISK_FORMAT=raw

# Extension to set before the compression extension.
IMG_DEFAULT_DISK_EXTENSION=

# Name of the partition layout from disk_layout.json
IMG_DEFAULT_DISK_LAYOUT=base

# Name of the target config format, default is no config
IMG_DEFAULT_CONF_FORMAT=

# Bundle configs and disk image into some archive
IMG_DEFAULT_BUNDLE_FORMAT=

# Memory size to use in any config files
IMG_DEFAULT_MEM=2048

# Number of CPUs to use in any config files
IMG_DEFAULT_CPUS=2

## qemu
IMG_qemu_uefi_DISK_FORMAT=qcow2
IMG_qemu_uefi_DISK_LAYOUT=vm
IMG_qemu_uefi_CONF_FORMAT=qemu_uefi
IMG_qemu_uefi_OEM_USE=qemu
IMG_qemu_uefi_OEM_PACKAGE=common-oem-files
IMG_qemu_uefi_OEM_SYSEXT=oem-qemu

## xen
IMG_xen_CONF_FORMAT=xl

## virtualbox
IMG_virtualbox_DISK_FORMAT=vmdk_ide
IMG_virtualbox_DISK_LAYOUT=vm
IMG_virtualbox_CONF_FORMAT=ovf_virtualbox
IMG_virtualbox_OEM_PACKAGE=oem-virtualbox

## vagrant
IMG_vagrant_FS_HOOK=box
IMG_vagrant_BUNDLE_FORMAT=box
IMG_vagrant_DISK_FORMAT=vmdk_ide
IMG_vagrant_DISK_LAYOUT=vagrant
IMG_vagrant_CONF_FORMAT=vagrant
IMG_vagrant_OEM_PACKAGE=oem-vagrant

## vagrant_virtualbox
IMG_vagrant_virtualbox_FS_HOOK=box
IMG_vagrant_virtualbox_BUNDLE_FORMAT=box
IMG_vagrant_virtualbox_DISK_FORMAT=vmdk_ide
IMG_vagrant_virtualbox_DISK_LAYOUT=vagrant
IMG_vagrant_virtualbox_CONF_FORMAT=vagrant
IMG_vagrant_virtualbox_OEM_PACKAGE=oem-vagrant-virtualbox

## vagrant_vmware
IMG_vagrant_vmware_fusion_FS_HOOK=box
IMG_vagrant_vmware_fusion_BUNDLE_FORMAT=box
IMG_vagrant_vmware_fusion_DISK_FORMAT=vmdk_scsi
IMG_vagrant_vmware_fusion_DISK_LAYOUT=vagrant
IMG_vagrant_vmware_fusion_CONF_FORMAT=vagrant_vmware_fusion
IMG_vagrant_vmware_fusion_OEM_PACKAGE=oem-vagrant

## vagrant_parallels
IMG_vagrant_parallels_FS_HOOK=box
IMG_vagrant_parallels_BUNDLE_FORMAT=box
IMG_vagrant_parallels_DISK_FORMAT=hdd
IMG_vagrant_parallels_DISK_LAYOUT=vagrant
IMG_vagrant_parallels_CONF_FORMAT=vagrant_parallels
IMG_vagrant_parallels_OEM_PACKAGE=oem-vagrant

## vmware
IMG_vmware_DISK_FORMAT=vmdk_scsi
IMG_vmware_DISK_LAYOUT=vm
IMG_vmware_CONF_FORMAT=vmx
IMG_vmware_OEM_USE=vmware
IMG_vmware_OEM_PACKAGE=common-oem-files
IMG_vmware_OEM_SYSEXT=oem-vmware

## vmware_ova
IMG_vmware_ova_DISK_FORMAT=vmdk_stream
IMG_vmware_ova_DISK_LAYOUT=vm
IMG_vmware_ova_CONF_FORMAT=ovf_vmware
IMG_vmware_ova_BUNDLE_FORMAT=ova
IMG_vmware_ova_OEM_USE=vmware
IMG_vmware_ova_OEM_PACKAGE=common-oem-files
IMG_vmware_ova_OEM_SYSEXT=oem-vmware

## vmware_raw
IMG_vmware_raw_OEM_USE=vmware
IMG_vmware_raw_OEM_PACKAGE=common-oem-files
IMG_vmware_raw_OEM_SYSEXT=oem-vmware

## vmware_insecure
IMG_vmware_insecure_DISK_FORMAT=vmdk_scsi
IMG_vmware_insecure_DISK_LAYOUT=vm
IMG_vmware_insecure_CONF_FORMAT=vmware_zip
IMG_vmware_insecure_OEM_PACKAGE=oem-vagrant-key

## parallels
IMG_parallels_BUNDLE_FORMAT=pvm_tgz
IMG_parallels_DISK_FORMAT=hdd
IMG_parallels_DISK_LAYOUT=vm
IMG_parallels_CONF_FORMAT=pvs

## ami
IMG_ami_vmdk_DISK_FORMAT=vmdk_stream
IMG_ami_vmdk_OEM_USE=ami
IMG_ami_vmdk_OEM_PACKAGE=common-oem-files
IMG_ami_vmdk_SYSEXT=oem-ami
IMG_ami_OEM_USE=ami
IMG_ami_OEM_PACKAGE=common-oem-files
IMG_ami_OEM_SYSEXT=oem-ami

## openstack
IMG_openstack_DISK_FORMAT=qcow2
IMG_openstack_DISK_LAYOUT=vm
IMG_openstack_OEM_PACKAGE=common-oem-files
IMG_openstack_OEM_USE=openstack
IMG_openstack_OEM_SYSEXT=oem-openstack

## openstack but without a resized root partition for more flexibility
IMG_openstack_mini_DISK_FORMAT=qcow2
IMG_openstack_mini_OEM_PACKAGE=common-oem-files
IMG_openstack_mini_OEM_USE=openstack
IMG_openstack_mini_OEM_SYSEXT=oem-openstack

## pxe, which is an cpio image
IMG_pxe_DISK_FORMAT=cpio
IMG_pxe_PARTITIONED_IMG=0
IMG_pxe_CONF_FORMAT=pxe
IMG_pxe_MEM=2048

## iso, which is an cpio image
IMG_iso_DISK_FORMAT=iso
IMG_iso_PARTITIONED_IMG=0
IMG_iso_CONF_FORMAT=iso
IMG_iso_MEM=2048

## gce, image tarball
IMG_gce_DISK_LAYOUT=vm
IMG_gce_CONF_FORMAT=gce
IMG_gce_OEM_PACKAGE=common-oem-files
IMG_gce_OEM_USE=gce
IMG_gce_OEM_SYSEXT=oem-gce

## rackspace
IMG_rackspace_OEM_PACKAGE=oem-rackspace
IMG_rackspace_vhd_DISK_FORMAT=vhd
IMG_rackspace_vhd_OEM_PACKAGE=oem-rackspace

## rackspace onmetal
IMG_rackspace_onmetal_DISK_FORMAT=qcow2
IMG_rackspace_onmetal_DISK_LAYOUT=onmetal
IMG_rackspace_onmetal_OEM_PACKAGE=oem-rackspace-onmetal

## cloudstack
IMG_cloudstack_OEM_PACKAGE=oem-cloudstack
IMG_cloudstack_vhd_DISK_FORMAT=vhd
IMG_cloudstack_vhd_OEM_PACKAGE=oem-cloudstack

## digitalocean
IMG_digitalocean_OEM_PACKAGE=common-oem-files
IMG_digitalocean_OEM_USE=digitalocean
IMG_digitalocean_OEM_SYSEXT=oem-digitalocean

## exoscale
IMG_exoscale_DISK_FORMAT=qcow2
IMG_exoscale_OEM_PACKAGE=oem-exoscale

## azure
IMG_azure_DISK_FORMAT=vhd_fixed
IMG_azure_DISK_LAYOUT=azure
IMG_azure_OEM_USE=azure
IMG_azure_OEM_PACKAGE=common-oem-files
IMG_azure_OEM_SYSEXT=oem-azure

## hetzner
IMG_hetzner_DISK_LAYOUT=vm
IMG_hetzner_OEM_USE=hetzner
IMG_hetzner_OEM_PACKAGE=common-oem-files
IMG_hetzner_OEM_SYSEXT=oem-hetzner

## hyper-v
IMG_hyperv_DISK_FORMAT=vhd
IMG_hyperv_OEM_PACKAGE=oem-hyperv

## hyper-v vhdx
IMG_hyperv_vhdx_DISK_FORMAT=vhdx
IMG_hyperv_vhdx_OEM_PACKAGE=oem-hyperv


## cloudsigma
IMG_cloudsigma_DISK_FORMAT=qcow2
IMG_cloudsigma_OEM_PACKAGE=oem-cloudsigma

## packet
IMG_packet_OEM_PACKAGE=common-oem-files
IMG_packet_OEM_SYSEXT=oem-packet
IMG_packet_OEM_USE=packet

## scaleway
IMG_scaleway_DISK_FORMAT=qcow2
IMG_scaleway_DISK_LAYOUT=vm
IMG_scaleway_OEM_PACKAGE=common-oem-files
IMG_scaleway_OEM_USE=scaleway
IMG_scaleway_OEM_SYSEXT=oem-scaleway
IMG_scaleway_DISK_EXTENSION=qcow2

## stackit
IMG_stackit_DISK_FORMAT=qcow2
IMG_stackit_DISK_LAYOUT=vm
IMG_stackit_OEM_PACKAGE=common-oem-files
IMG_stackit_OEM_USE=stackit
IMG_stackit_OEM_SYSEXT=oem-stackit

## kubevirt
IMG_kubevirt_DISK_FORMAT=qcow2
IMG_kubevirt_DISK_LAYOUT=vm
IMG_kubevirt_OEM_PACKAGE=common-oem-files
IMG_kubevirt_OEM_USE=kubevirt
IMG_kubevirt_OEM_SYSEXT=oem-kubevirt
IMG_kubevirt_DISK_EXTENSION=qcow2

## akamai (Linode)
IMG_akamai_OEM_PACKAGE=common-oem-files
IMG_akamai_OEM_USE=akamai
IMG_akamai_OEM_SYSEXT=oem-akamai

# proxmoxve
IMG_proxmoxve_DISK_FORMAT=qcow2
IMG_proxmoxve_DISK_LAYOUT=vm
IMG_proxmoxve_OEM_PACKAGE=common-oem-files
IMG_proxmoxve_OEM_USE=proxmoxve
IMG_proxmoxve_OEM_SYSEXT=oem-proxmoxve

###########################################################

# Print the default vm type for the specified board
get_default_vm_type() {
    local board="$1"
    case "$board" in
    amd64-usr)
        echo "qemu_uefi"
        ;;
    arm64-usr)
        echo "qemu_uefi"
        ;;
    *)
        return 1
        ;;
    esac
}

# Validate and set the vm type to use for the rest of the functions
set_vm_type() {
    local vm_type="$1"
    local valid_type
    for valid_type in "${VALID_IMG_TYPES[@]}"; do
        if [[ "${vm_type}" == "${valid_type}" ]]; then
            VM_IMG_TYPE="${vm_type}"
            return 0
        fi
    done
    return 1
}

# Validate and set the oem package, colon delimited USE optional
set_vm_oem_pkg() {
    local oem_pkg="${1%:*}" oem_use="${1##*:}"
    local valid_pkg
    for valid_pkg in "${VALID_OEM_PACKAGES[@]}"; do
        if [[ "${oem_pkg}" == "${valid_pkg}" ]]; then
            IMG_FORCE_OEM_PACKAGE="oem-${oem_pkg}"
            IMG_FORCE_OEM_USE="${oem_use}"
            return 0
        fi
    done
    return 1
}

# Validate and set source vm image path
set_vm_paths() {
    local src_dir="${1}"; shift
    local dst_dir="${1}"; shift
    local src_name="${1}"; shift
    local sysext_base_name="${1}"; shift

    VM_SRC_IMG="${src_dir}/${src_name}"
    if [[ ! -f "${VM_SRC_IMG}" ]]; then
        die "Source image does not exist: ${VM_SRC_IMG}"
    fi
    VM_SRC_SYSEXT_IMG="${src_dir}/${sysext_base_name}"
    if [[ ! -f "${VM_SRC_SYSEXT_IMG}" ]]; then
        die "Sysext base image does not exist: ${VM_SRC_SYSEXT_IMG}"
    fi

    local dst_name="$(_src_to_dst_name "${src_name}" "_image.$(_disk_ext)")"
    VM_DST_IMG="${dst_dir}/${dst_name}"
    VM_TMP_DIR="${dst_dir}/${dst_name}.vmtmpdir"
    VM_TMP_IMG="${VM_TMP_DIR}/disk_image.bin"
    VM_TMP_ROOT="${VM_TMP_DIR}/rootfs"
    VM_NAME="$(_src_to_dst_name "${src_name}" "")-${FLATCAR_VERSION}"
    VM_README="${dst_dir}/$(_src_to_dst_name "${src_name}" ".README")"

    # Make VM_NAME safe for use as a hostname
    VM_NAME="${VM_NAME//./-}"
    VM_NAME="${VM_NAME//+/-}"
}

_get_vm_opt() {
    local opt="$1"
    local type_opt="IMG_${VM_IMG_TYPE}_${opt}"
    local default_opt="IMG_DEFAULT_${opt}"
    local force_opt="IMG_FORCE_${opt}"
    echo "${!force_opt:-${!type_opt:-${!default_opt}}}"
}

# Translate source image names to output names.
# This keeps naming consistent across all vm types.
_src_to_dst_name() {
    local src_img="$1"
    local suffix="$2"
    echo "${1%_image.bin}_${VM_IMG_TYPE}${suffix}"
}

# Generate a destination name based on file extension
_dst_name() {
    local src_name=$(basename "$VM_SRC_IMG")
    local suffix="$1"
    echo "${src_name%_image.bin}_${VM_IMG_TYPE}${suffix}"
}

# Return the destination directory
_dst_dir() {
    echo $(dirname "$VM_DST_IMG")
}

# Combine dst name and dir
_dst_path() {
    echo "$(_dst_dir)/$(_dst_name "$@")"
}

# Get the proper disk format extension.
_disk_ext() {
    local disk_format=$(_get_vm_opt DISK_FORMAT)
    local disk_extension=$(_get_vm_opt DISK_EXTENSION)
    if [[ -n ${disk_extension} ]]; then
	echo "${disk_extension}"
	return 0
    fi
    case ${disk_format} in
        raw) echo bin;;
        qcow2) echo img;;
        cpio) echo cpio.gz;;
        vmdk_ide) echo vmdk;;
        vmdk_scsi) echo vmdk;;
        vmdk_stream) echo vmdk;;
        hdd) echo hdd;;
        vhd) echo vhd;;
        vhd_fixed) echo vhd;;
        vhdx) echo vhdx;;
        *) echo "${disk_format}";;
    esac
}

setup_disk_image() {
    local disk_layout="${1:-$(_get_vm_opt DISK_LAYOUT)}"

    rm -rf "${VM_TMP_DIR}"
    mkdir -p "${VM_TMP_DIR}" "${VM_TMP_ROOT}"

    info "Initializing new disk image..."
    cp --sparse=always "${VM_SRC_IMG}" "${VM_TMP_IMG}"

    if [[ $(_get_vm_opt PARTITIONED_IMG) -eq 1 ]]; then
      "${BUILD_LIBRARY_DIR}/disk_util" --disk_layout="${disk_layout}" \
          update "${VM_TMP_IMG}"
    fi

    assert_image_size "${VM_TMP_IMG}" raw

    info "Mounting image to $(relpath "${VM_TMP_ROOT}")"
    "${BUILD_LIBRARY_DIR}/disk_util" --disk_layout="${disk_layout}" \
        mount "${VM_TMP_IMG}" "${VM_TMP_ROOT}"

    # The only filesystems after this point that may be modified are OEM
    # and on rare cases ESP.
    # Note: it would be more logical for disk_util to mount things read-only
    # to begin with but I'm having trouble making that work reliably.
    # When mounting w/ ro the automatically allocated loop device will
    # also be configured as read-only. blockdev --setrw will change that
    # but io will start throwing errors so that clearly isn't sufficient.
    sudo mount -o remount,ro "${VM_TMP_ROOT}"

    VM_GROUP=$(grep --no-messages --no-filename ^GROUP= \
        "${VM_TMP_ROOT}/usr/share/flatcar/update.conf" \
        "${VM_TMP_ROOT}/etc/flatcar/update.conf" | \
        tail -n 1 | sed -e 's/^GROUP=//')
    if [[ -z "${VM_GROUP}" ]]; then
        die "Unable to determine update group for this image."
    fi
}

# If the current type defines a oem package install it to the given fs image.
install_oem_package() {
    local oem_pkg=$(_get_vm_opt OEM_PACKAGE)
    local oem_use=$(_get_vm_opt OEM_USE)
    local oem_tmp="${VM_TMP_DIR}/oem"

    if [[ -z "${oem_pkg}" ]]; then
        return 0
    fi

    # Split into two steps because we want to always install $oem_pkg from
    # the ebuild (build_packages doesn't handle it) *but* we never want to
    # build anything else from source here. emerge doesn't have a way to
    # enforce this in a single command.
    info "Building ${oem_pkg}"
    USE="${oem_use}" emerge-${BOARD} \
        --nodeps --buildpkgonly --usepkg n \
        --verbose "${oem_pkg}"

    local getbinpkg
    if [[ ${FLAGS_getbinpkg} -eq ${FLAGS_TRUE} ]]; then
        getbinpkg=--getbinpkg
    fi

    info "Installing ${oem_pkg} to OEM partition"
    USE="${oem_use}" emerge-${BOARD} \
        --root="${oem_tmp}" --sysroot="${oem_tmp}" \
        --usepkgonly ${getbinpkg} \
        --verbose --jobs=2 "${oem_pkg}"
    sudo rsync -a "${oem_tmp}/oem/" "${VM_TMP_ROOT}/oem/"
    sudo rm -rf "${oem_tmp}"
}

# Write the OEM sysext file into the OEM partition.
install_oem_sysext() {
    local oem_sysext=$(_get_vm_opt OEM_SYSEXT)

    if [[ -z "${oem_sysext}" ]]; then
        return 0
    fi

    local built_sysext_dir="${FLAGS_to}/${oem_sysext}-sysext"
    local built_sysext_filename="${oem_sysext}.raw"
    local built_sysext_path="${built_sysext_dir}/${built_sysext_filename}"
    local version="${FLATCAR_VERSION}"
    local metapkg="coreos-base/${oem_sysext}"
    local build_sysext_flags=(
        --board="${BOARD}"
        --squashfs_base="${VM_SRC_SYSEXT_IMG}"
        --image_builddir="${built_sysext_dir}"
        --metapkgs="${metapkg}"
    )
    local overlay_path mangle_fs
    overlay_path=$(portageq get_repo_path / coreos-overlay)
    mangle_fs="${overlay_path}/${metapkg}/files/manglefs.sh"
    if [[ -x "${mangle_fs}" ]]; then
        build_sysext_flags+=(
            --manglefs_script="${mangle_fs}"
        )
    fi

    mkdir -p "${built_sysext_dir}"
    sudo "${build_sysext_env[@]}" "${SCRIPT_ROOT}/build_sysext" "${build_sysext_flags[@]}" "${oem_sysext}"

    local installed_sysext_oem_dir='/oem/sysext'
    local installed_sysext_file_prefix="${oem_sysext}-${version}"
    local installed_sysext_filename="${installed_sysext_file_prefix}.raw"
    local installed_sysext_abspath="${installed_sysext_oem_dir}/${installed_sysext_filename}"
    info "Installing ${oem_sysext} sysext"
    sudo install -Dpm 0644 \
         "${built_sysext_path}" \
         "${VM_TMP_ROOT}${installed_sysext_abspath}" ||
        die "Could not install ${oem_sysext} sysext"
    # Move sysext image and reports to a destination directory to
    # upload them, thus making them available as separate artifacts to
    # download.
    local upload_dir to_move
    upload_dir="$(_dst_dir)"
    for to_move in "${built_sysext_dir}/${oem_sysext}"*; do
        mv "${to_move}" "${upload_dir}/${to_move##*/}"
    done
    # Generate dev-key-signed update payload for testing
    delta_generator \
      -private_key "/usr/share/update_engine/update-payload-key.key.pem" \
      -new_image "${upload_dir}/${built_sysext_filename}" \
      -out_file "${upload_dir}/flatcar_test_update-${oem_sysext}.gz"
    # Remove sysext_dir if building sysext and installing it
    # succeeded.
    rm -rf "${built_sysext_dir}"

    # Mark the installed sysext as active.
    sudo touch "${VM_TMP_ROOT}${installed_sysext_oem_dir}/active-${oem_sysext}"
}

# Any other tweaks required?
run_fs_hook() {
    local fs_hook=$(_get_vm_opt FS_HOOK)
    if [[ -n "${fs_hook}" ]]; then
        info "Running ${fs_hook} fs hook"
        _run_${fs_hook}_fs_hook "$@"
    fi
}

_run_box_fs_hook() {
    # Copy basic Vagrant configs from OEM
    mkdir -p "${VM_TMP_DIR}/box"
    cp -R "${VM_TMP_ROOT}/oem/box/." "${VM_TMP_DIR}/box"
    sudo rm -fr "${VM_TMP_ROOT}/oem/box"
}

# Write the vm disk image to the target directory in the proper format
write_vm_disk() {
    if [[ $(_get_vm_opt PARTITIONED_IMG) -eq 1 ]]; then
        # unmount before creating block device images
        cleanup_mounts "${VM_TMP_ROOT}"
    fi

    local disk_format=$(_get_vm_opt DISK_FORMAT)
    info "Writing $disk_format image $(basename "${VM_DST_IMG}")"
    _write_${disk_format}_disk "${VM_TMP_IMG}" "${VM_DST_IMG}"

    # We now only support building qemu_uefi and set up symlinks
    # for the qemu and qemu_uefi_secure images
    if [ "${VM_IMG_TYPE}" = qemu_uefi ]; then
        local qemu="${VM_DST_IMG/qemu_uefi/qemu}"
        local qemu_uefi_secure="${VM_DST_IMG/qemu_uefi/qemu_uefi_secure}"
        local target_basename
        target_basename=$(basename "${VM_DST_IMG}")
        if [ "${BOARD}" = amd64-usr ]; then
          ln -fs "${target_basename}" "${qemu}"
          VM_GENERATED_FILES+=( "${qemu}" )
        fi
        ln -fs "${target_basename}" "${qemu_uefi_secure}"
        VM_GENERATED_FILES+=( "${qemu_uefi_secure}" )
    fi

    # Add disk image to final file list if it isn't going to be bundled
    if [[ -z "$(_get_vm_opt BUNDLE_FORMAT)" ]]; then
        VM_GENERATED_FILES+=( "${VM_DST_IMG}" )
    fi
}

_write_raw_disk() {
    mv "$1" "$2"
}

_write_qcow2_disk() {
    qemu-img convert -f raw "$1" -O qcow2 -c -o compat=0.10 "$2"
    assert_image_size "$2" qcow2
}

_write_vhd_disk() {
    qemu-img convert -f raw "$1" -O vpc -o force_size "$2"
    assert_image_size "$2" vpc
}

_write_vhd_fixed_disk() {
    qemu-img convert -f raw "$1" -O vpc -o subformat=fixed,force_size "$2"
    assert_image_size "$2" vpc
}

_write_vhdx_disk() {
    qemu-img convert -f raw "$1" -O vhdx -o subformat=dynamic "$2"
    assert_image_size "$2" vhdx
}

_write_vmdk_ide_disk() {
    qemu-img convert -f raw "$1" -O vmdk -o adapter_type=ide "$2"
    assert_image_size "$2" vmdk
}

_write_vmdk_scsi_disk() {
    qemu-img convert -f raw "$1" -O vmdk -o adapter_type=lsilogic "$2"
    assert_image_size "$2" vmdk
}

_write_hdd_disk() {
    "${BUILD_LIBRARY_DIR}/write_hdd.sh" \
        --input_disk_image "$1" \
        --input_disk_format "raw" \
        --output_disk "${2}"
}

_write_vmdk_stream_disk() {
    # requires two pass conversion, qemu-img doesn't properly support the
    # stream-optimized VMDK format. The special vmdk-convert tool only takes
    # VMDK images as an import format.
    local tmpvmdk="${VM_TMP_DIR}/tmp.vmdk"
    qemu-img convert -f raw "$1" -O vmdk -o adapter_type=lsilogic "${tmpvmdk}"
    vmdk-convert "${tmpvmdk}" "$2"
    assert_image_size "$2" vmdk
}

_write_cpio_common() {
    local cpio_target="${VM_TMP_DIR}/rootcpio"
    local dst_dir=$(_dst_dir)
    local vmlinuz_name="$(_dst_name ".vmlinuz")"
    local base_dir="${VM_TMP_ROOT}/usr"

    sudo mkdir -p "${cpio_target}/etc"

    # Inject /usr/.noupdate into squashfs to disable update_engine
    echo "/.noupdate f 444 root root echo -n" >"${VM_TMP_DIR}/extra"

    # Set correct group for PXE/ISO, which has no writeable /etc
    echo /share/flatcar/update.conf f 644 root root \
        "sed -e 's/GROUP=.*$/GROUP=${VM_GROUP}/' ${base_dir}/share/flatcar/update.conf" \
        >> "${VM_TMP_DIR}/extra"

    local -a mksquashfs_opts=(
        -pf "${VM_TMP_DIR}/extra"
        -xattrs-exclude '^btrfs.'
        # mksquashfs doesn't like overwriting existing files with
        # pseudo-files, so tell it to ignore the existing file instead
        #
        # also, this must be the last option
        -e share/flatcar/update.conf
    )

    # Build the squashfs, embed squashfs into a gzipped cpio
    pushd "${cpio_target}" >/dev/null
    sudo mksquashfs "${base_dir}" "./usr.squashfs" "${mksquashfs_opts[@]}"
    find . | cpio -o -H newc | gzip > "$2"
    popd >/dev/null

}

# The cpio "disk" is a bit special,
# consists of a kernel+initrd not a block device
_write_cpio_disk() {
    local base_dir="${VM_TMP_ROOT}"
    local dst_dir=$(_dst_dir)
    local vmlinuz_name="$(_dst_name ".vmlinuz")"
    local grub_name="$(_dst_name "_grub.efi")"
    _write_cpio_common $@
    # Pull the kernel and loader out of the filesystem
    ln -fs flatcar_production_image.vmlinuz "${dst_dir}/${vmlinuz_name}"

    local efi_file
    case $BOARD in
        amd64-usr) efi_file="grubx64.efi" ;;
        arm64-usr) efi_file="bootaa64.efi" ;;
    esac

    cp "${base_dir}/boot/EFI/boot/${efi_file}" "${dst_dir}/${grub_name}"
    VM_GENERATED_FILES+=( "${dst_dir}/${vmlinuz_name}" "${dst_dir}/${grub_name}" )
}

_write_iso_disk() {
    local base_dir="${VM_TMP_ROOT}/usr"
    local iso_target="${VM_TMP_DIR}/rootiso"
    local dst_dir=$(_dst_dir)
    local vmlinuz_name="$(_dst_name ".vmlinuz")"

    mkdir "${iso_target}"
    pushd "${iso_target}" >/dev/null
    mkdir isolinux syslinux flatcar
    _write_cpio_common "$1" "${iso_target}/flatcar/cpio.gz"
    cp "${VM_TMP_ROOT}"/boot/flatcar/vmlinuz-a "${iso_target}/flatcar/vmlinuz"
    cp -R /usr/share/syslinux/* isolinux/
    cat<<EOF > isolinux/isolinux.cfg
INCLUDE /syslinux/syslinux.cfg
EOF
    cat<<EOF > syslinux/syslinux.cfg
default flatcar
prompt 1
timeout 15

label flatcar
  menu default
  kernel /flatcar/vmlinuz
  append initrd=/flatcar/cpio.gz flatcar.autologin
EOF
    mkisofs -v -l -r -J -o $2 -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table .
    isohybrid $2
    popd >/dev/null
}

# If a config format is defined write it!
write_vm_conf() {
    local conf_format=$(_get_vm_opt CONF_FORMAT)
    if [[ -n "${conf_format}" ]]; then
        info "Writing ${conf_format} configuration"
        _write_${conf_format}_conf "$@"
    fi
}

_write_qemu_common() {
    local script="$1"
    local vm_mem="$(_get_vm_opt MEM)"

    sed -e "s%^VM_NAME=.*%VM_NAME='${VM_NAME}'%" \
        -e "s%^VM_MEMORY=.*%VM_MEMORY='${vm_mem}'%" \
        -e "s%^VM_BOARD=.*%VM_BOARD='${BOARD}'%" \
        "${BUILD_LIBRARY_DIR}/qemu_template.sh" > "${script}"
    chmod +x "${script}"

    cat >"${VM_README}" <<EOF
If you have qemu installed (or in the SDK), you can start the image with:
  cd path/to/image
  ./$(basename "${script}") -curses

If you need to use a different ssh key or different ssh port:
  ./$(basename "${script}") -a ~/.ssh/authorized_keys -p 2223 -- -curses

If you rather you can use the -nographic option instad of -curses. In this
mode you can switch from the vm to the qemu monitor console with: Ctrl-a c
See the qemu man page for more details on the monitor console.

SSH into that host with:
  ssh 127.0.0.1 -p 2222
EOF

    VM_GENERATED_FILES+=( "${script}" "${VM_README}" )
}

_write_qemu_conf() {
    local script="$(_dst_dir)/$(_dst_name ".sh")"
    local dst_name=$(basename "$VM_DST_IMG")

    _write_qemu_common "${script}"
    sed -e "s%^VM_IMAGE=.*%VM_IMAGE=\"\${SCRIPT_DIR}/${dst_name}\"%" -i "${script}"
}

_write_qemu_uefi_conf() {
    local flash_ro="$(_dst_name "_efi_code.qcow2")"
    local flash_rw="$(_dst_name "_efi_vars.qcow2")"
    local script="$(_dst_dir)/$(_dst_name ".sh")"

    _write_qemu_conf

    case $BOARD in
        amd64-usr)
            cp "/usr/share/edk2/OvmfX64/OVMF_CODE_4M.qcow2" "$(_dst_dir)/${flash_ro}"
            cp "/usr/share/edk2/OvmfX64/OVMF_VARS_4M.qcow2" "$(_dst_dir)/${flash_rw}"
            ;;
        arm64-usr)
            cp "/usr/share/edk2/ArmVirtQemu-AARCH64/QEMU_EFI.qcow2" "$(_dst_dir)/${flash_ro}"
            cp "/usr/share/edk2/ArmVirtQemu-AARCH64/QEMU_VARS.qcow2" "$(_dst_dir)/${flash_rw}"
            ;;
    esac

    sed -e "s%^VM_PFLASH_RO=.*%VM_PFLASH_RO=\"\${SCRIPT_DIR}/${flash_ro}\"%" \
        -e "s%^VM_PFLASH_RW=.*%VM_PFLASH_RW=\"\${SCRIPT_DIR}/${flash_rw}\"%" -i "${script}"
    VM_GENERATED_FILES+=( "$(_dst_dir)/${flash_ro}" "$(_dst_dir)/${flash_rw}" )

    # We now only support building qemu_uefi and generate the
    # other artifacts from here
    if [ "${VM_IMG_TYPE}" = qemu_uefi ]; then
      local qemu="${VM_DST_IMG/qemu_uefi/qemu}"
      local qemu_uefi_secure="${VM_DST_IMG/qemu_uefi/qemu_uefi_secure}"
      local qemu_name="${VM_NAME/qemu_uefi/qemu}"
      local qemu_uefi_secure_name="${VM_NAME/qemu_uefi/qemu_uefi_secure}"
      if [ "${BOARD}" = amd64-usr ]; then
        VM_IMG_TYPE=qemu VM_DST_IMG="${qemu}" VM_NAME="${qemu_name}" _write_qemu_conf
      fi
      VM_IMG_TYPE=qemu_uefi_secure VM_DST_IMG="${qemu_uefi_secure}" VM_NAME="${qemu_uefi_secure_name}" _write_qemu_uefi_secure_conf
    fi
}

_write_qemu_uefi_secure_conf() {
    local flash_rw="$(_dst_name "_efi_vars.qcow2")"
    local flash_ro="$(_dst_name "_efi_code.qcow2")"
    local script="$(_dst_dir)/$(_dst_name ".sh")"
    local owner="00000000-0000-0000-0000-000000000000"
    local flash_in

    _write_qemu_uefi_conf

    case $BOARD in
        amd64-usr)
            cp "/usr/share/edk2/OvmfX64/OVMF_CODE_4M.secboot.qcow2" "$(_dst_dir)/${flash_ro}"
            flash_in="/usr/share/edk2/OvmfX64/OVMF_VARS_4M.secboot.qcow2"
            ;;
        arm64-usr)
            # This firmware is not considered secure due to the lack of an SMM
            # implementation, which is needed to protect the variable store, but
            # it's only supposed to be used for testing anyway.
            cp "/usr/share/edk2/ArmVirtQemu-AARCH64/QEMU_EFI.secboot_INSECURE.qcow2" "$(_dst_dir)/${flash_ro}"
            flash_in="/usr/share/edk2/ArmVirtQemu-AARCH64/QEMU_VARS.secboot_INSECURE.qcow2"
            ;;
    esac

    # TODO: Remove the temporary flatcar shim signing cert
    virt-fw-vars \
        --input "${flash_in}" \
        --output "$(_dst_dir)/${flash_rw}" \
        --add-db "${owner}" /usr/share/sb_keys/DB.crt \
        --add-db "${owner}" "${BUILD_LIBRARY_DIR}/flatcar-sb-dev-shim-2025.cert"

    sed -e "s%^SECURE_BOOT=.*%SECURE_BOOT=1%" -i "${script}"
}

_write_pxe_conf() {
    local script="$(_dst_dir)/$(_dst_name ".sh")"
    local vmlinuz_name="$(_dst_name ".vmlinuz")"
    local dst_name=$(basename "$VM_DST_IMG")

    _write_qemu_common "${script}"
    sed -e "s%^VM_KERNEL=.*%VM_KERNEL=\"\${SCRIPT_DIR}/${vmlinuz_name}\"%" \
        -e "s%^VM_INITRD=.*%VM_INITRD=\"\${SCRIPT_DIR}/${dst_name}\"%" -i "${script}"

    cat >>"${VM_README}" <<EOF

You can pass extra kernel parameters with -append, for example:
  ./$(basename "${script}") -curses -append 'sshkey="PUT AN SSH KEY HERE"'

When using -nographic or -serial you must also enable the serial console:
  ./$(basename "${script}") -nographic -append 'console=ttyS0,115200n8'
EOF
    local packetipxe="$(_dst_dir)/flatcar_production_packet.ipxe"
    cat > "$packetipxe" <<EOF
#!ipxe

kernel flatcar_production_pxe.vmlinuz initrd=flatcar_production_pxe_image.cpio.gz flatcar.first_boot=1 flatcar.oem.id=packet console=ttyS1,115200n8 flatcar.autologin
initrd flatcar_production_pxe_image.cpio.gz
boot
EOF
    VM_GENERATED_FILES+=( "$packetipxe" )
}

_write_iso_conf() {
    local script="$(_dst_dir)/$(_dst_name ".sh")"
    local dst_name=$(basename "$VM_DST_IMG")
    _write_qemu_common "${script}"
    sed -e "s%^VM_CDROM=.*%VM_CDROM=\"\${SCRIPT_DIR}/${dst_name}\"%" -i "${script}"
}

# Generate the vmware config file
# A good reference doc: http://www.sanbarrow.com/vmx.html
_write_vmx_conf() {
    local vm_mem="${1:-$(_get_vm_opt MEM)}"
    local src_name=$(basename "$VM_SRC_IMG")
    local dst_name=$(basename "$VM_DST_IMG")
    local dst_dir=$(dirname "$VM_DST_IMG")
    local vmx_path="${dst_dir}/$(_src_to_dst_name "${src_name}" ".vmx")"
    cat >"${vmx_path}" <<EOF
#!/usr/bin/vmware
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "11"
cleanShutdown = "TRUE"
displayName = "${VM_NAME}"
ethernet0.addressType = "generated"
ethernet0.present = "TRUE"
ethernet0.virtualDev = "vmxnet3"
floppy0.present = "FALSE"
guestOS = "other26xlinux-64"
memsize = "${vm_mem}"
powerType.powerOff = "soft"
powerType.powerOn = "hard"
powerType.reset = "hard"
powerType.suspend = "hard"
scsi0.present = "TRUE"
scsi0.virtualDev = "pvscsi"
scsi0:0.fileName = "${dst_name}"
scsi0:0.present = "TRUE"
sound.present = "FALSE"
usb.generic.autoconnect = "FALSE"
usb.present = "TRUE"
rtc.diffFromUTC = 0
pciBridge0.present = "TRUE"
pciBridge4.present = "TRUE"
pciBridge4.virtualDev = "pcieRootPort"
pciBridge4.functions = "8"
pciBridge5.present = "TRUE"
pciBridge5.virtualDev = "pcieRootPort"
pciBridge5.functions = "8"
pciBridge6.present = "TRUE"
pciBridge6.virtualDev = "pcieRootPort"
pciBridge6.functions = "8"
pciBridge7.present = "TRUE"
pciBridge7.virtualDev = "pcieRootPort"
pciBridge7.functions = "8"
hpet0.present = "TRUE"
vcpu.hotadd = "TRUE"
mem.hotadd = "TRUE"
EOF
    # Only upload the vmx if it won't be bundled
    if [[ -z "$(_get_vm_opt BUNDLE_FORMAT)" ]]; then
        VM_GENERATED_FILES+=( "${vmx_path}" )
    fi
}

_write_vmware_zip_conf() {
    local src_name=$(basename "$VM_SRC_IMG")
    local dst_name=$(basename "$VM_DST_IMG")
    local dst_dir=$(dirname "$VM_DST_IMG")
    local vmx_path="${dst_dir}/$(_src_to_dst_name "${src_name}" ".vmx")"
    local vmx_file=$(basename "${vmx_path}")
    local zip="${dst_dir}/$(_src_to_dst_name "${src_name}" ".zip")"

    _write_vmx_conf "$1"

    # Move the disk/vmx to tmp, they will be zipped.
    mv "${VM_DST_IMG}" "${VM_TMP_DIR}/${dst_name}"
    mv "${vmx_path}" "${VM_TMP_DIR}/${vmx_file}"
    cat > "${VM_TMP_DIR}/insecure_ssh_key" <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzI
w+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoP
kcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2
hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NO
Td0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcW
yLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQIBIwKCAQEA4iqWPJXtzZA68mKd
ELs4jJsdyky+ewdZeNds5tjcnHU5zUYE25K+ffJED9qUWICcLZDc81TGWjHyAqD1
Bw7XpgUwFgeUJwUlzQurAv+/ySnxiwuaGJfhFM1CaQHzfXphgVml+fZUvnJUTvzf
TK2Lg6EdbUE9TarUlBf/xPfuEhMSlIE5keb/Zz3/LUlRg8yDqz5w+QWVJ4utnKnK
iqwZN0mwpwU7YSyJhlT4YV1F3n4YjLswM5wJs2oqm0jssQu/BT0tyEXNDYBLEF4A
sClaWuSJ2kjq7KhrrYXzagqhnSei9ODYFShJu8UWVec3Ihb5ZXlzO6vdNQ1J9Xsf
4m+2ywKBgQD6qFxx/Rv9CNN96l/4rb14HKirC2o/orApiHmHDsURs5rUKDx0f9iP
cXN7S1uePXuJRK/5hsubaOCx3Owd2u9gD6Oq0CsMkE4CUSiJcYrMANtx54cGH7Rk
EjFZxK8xAv1ldELEyxrFqkbE4BKd8QOt414qjvTGyAK+OLD3M2QdCQKBgQDtx8pN
CAxR7yhHbIWT1AH66+XWN8bXq7l3RO/ukeaci98JfkbkxURZhtxV/HHuvUhnPLdX
3TwygPBYZFNo4pzVEhzWoTtnEtrFueKxyc3+LjZpuo+mBlQ6ORtfgkr9gBVphXZG
YEzkCD3lVdl8L4cw9BVpKrJCs1c5taGjDgdInQKBgHm/fVvv96bJxc9x1tffXAcj
3OVdUN0UgXNCSaf/3A/phbeBQe9xS+3mpc4r6qvx+iy69mNBeNZ0xOitIjpjBo2+
dBEjSBwLk5q5tJqHmy/jKMJL4n9ROlx93XS+njxgibTvU6Fp9w+NOFD/HvxB3Tcz
6+jJF85D5BNAG3DBMKBjAoGBAOAxZvgsKN+JuENXsST7F89Tck2iTcQIT8g5rwWC
P9Vt74yboe2kDT531w8+egz7nAmRBKNM751U/95P9t88EDacDI/Z2OwnuFQHCPDF
llYOUI+SpLJ6/vURRbHSnnn8a/XG+nzedGH5JGqEJNQsz+xT2axM0/W/CRknmGaJ
kda/AoGANWrLCz708y7VYgAtW2Uf1DPOIYMdvo6fxIB5i9ZfISgcJ/bbCUkFrhoH
+vq/5CIWxCPp0f85R4qxxQ5ihxJ0YDQT9Jpx4TMss4PSavPaBH3RXow5Ohe+bYoQ
NE5OgEXk2wVfZczCZpigBKbKZHNYcelXtTt/nP3rsCuGcM4h53s=
-----END RSA PRIVATE KEY-----
EOF
    chmod 600 "${VM_TMP_DIR}/insecure_ssh_key"

    zip --junk-paths "${zip}" \
        "${VM_TMP_DIR}/${dst_name}" \
        "${VM_TMP_DIR}/${vmx_file}" \
        "${VM_TMP_DIR}/insecure_ssh_key"

    cat > "${VM_README}" <<EOF
Use insecure_ssh_key in the zip for login access.
TODO: more instructions!
EOF

    # Replace list, not append, since we packaged up the disk image.
    VM_GENERATED_FILES=( "${zip}" "${VM_README}" )
}

# Generate a new-style (xl) Xen config file for both pvgrub and pygrub
_write_xl_conf() {
    local vm_mem="${1:-$(_get_vm_opt MEM)}"
    local src_name=$(basename "$VM_SRC_IMG")
    local dst_name=$(basename "$VM_DST_IMG")
    local dst_dir=$(dirname "$VM_DST_IMG")
    local pygrub="${dst_dir}/$(_src_to_dst_name "${src_name}" "_pygrub.cfg")"
    local pvgrub="${dst_dir}/$(_src_to_dst_name "${src_name}" "_pvgrub.cfg")"
    local disk_format=$(_get_vm_opt DISK_FORMAT)

    # Set up the few differences between pygrub and pvgrub
    echo '# Xen PV config using pygrub' > "${pygrub}"
    echo 'bootloader = "pygrub"' >> "${pygrub}"

    echo '# Xen PV config using pvgrub' > "${pvgrub}"
    echo 'kernel = "/usr/lib/xen/boot/pv-grub-x86_64.gz"' >> "${pvgrub}"
    echo 'extra = "(hd0,0)/boot/grub/menu.lst"' >> "${pvgrub}"

    # The rest is the same
    tee -a "${pygrub}" >> "${pvgrub}" <<EOF

builder = "generic"
name = "${VM_NAME}"

memory = "${vm_mem}"
vcpus = 2
# TODO(marineam): networking...
vif = [ ]
disk = [ '${dst_name},${disk_format},xvda' ]
EOF

    cat > "${VM_README}" <<EOF
If this is a Xen Dom0 host with pygrub you can start the vm with:
cd $(relpath "${dst_dir}")
xl create -c "${pygrub##*/}"

Or with pvgrub instead:
xl create -c "${pvgrub##*/}"

Detach from the console with ^] and reattach with:
xl console ${VM_NAME}

Kill the vm with:
xl destroy ${VM_NAME}
EOF
    VM_GENERATED_FILES+=( "${pygrub}" "${pvgrub}" "${VM_README}" )
}

_write_ovf_virtualbox_conf() {
    local vm_mem="${1:-$(_get_vm_opt MEM)}"
    local src_name=$(basename "$VM_SRC_IMG")
    local dst_name=$(basename "$VM_DST_IMG")
    local dst_dir=$(dirname "$VM_DST_IMG")
    local ovf="${dst_dir}/$(_src_to_dst_name "${src_name}" ".ovf")"

    "${BUILD_LIBRARY_DIR}/virtualbox_ovf.sh" \
            --vm_name "$VM_NAME" \
            --disk_vmdk "$VM_DST_IMG" \
            --memory_size "$vm_mem" \
            --output_ovf "$ovf"

    local ovf_name=$(basename "${ovf}")
    cat > "${VM_README}" <<EOF
Copy ${dst_name} and ${ovf_name} to a VirtualBox host and run:
VBoxManage import ${ovf_name}
EOF

    VM_GENERATED_FILES+=( "$ovf" "${VM_README}" )
}

_write_vagrant_conf() {
    local vm_mem="${1:-$(_get_vm_opt MEM)}"
    local ovf="${VM_TMP_DIR}/box/box.ovf"
    local mac="${VM_TMP_DIR}/box/base_mac.rb"

    "${BUILD_LIBRARY_DIR}/virtualbox_ovf.sh" \
            --vm_name "$VM_NAME" \
            --disk_vmdk "${VM_DST_IMG}" \
            --memory_size "$vm_mem" \
            --output_ovf "$ovf" \
            --output_vagrant "$mac"
}

_write_vagrant_vmware_fusion_conf() {
    local vm_mem="${1:-$(_get_vm_opt MEM)}"
    local vmx=$(_dst_path ".vmx")

    mkdir -p "${VM_TMP_DIR}/box"
    _write_vmx_conf ${vm_mem}
    mv "${vmx}" "${VM_TMP_DIR}/box"
}

_write_vagrant_parallels_conf() {
    local vm_mem="${1:-$(_get_vm_opt MEM)}"
    local pvs=$(_dst_path ".pvs")

    "${BUILD_LIBRARY_DIR}/parallels_pvs.sh" \
            --vm_name "$VM_NAME" \
            --disk_image "$VM_DST_IMG" \
            --memory_size "$vm_mem" \
            --output_pvs "$pvs" \
            --template
}

_write_pvs_conf() {
    local vm_mem="${1:-$(_get_vm_opt MEM)}"
    local pvs=$(_dst_path ".pvs")

    "${BUILD_LIBRARY_DIR}/parallels_pvs.sh" \
            --vm_name "$VM_NAME" \
            --disk_image "$VM_DST_IMG" \
            --memory_size "$vm_mem" \
            --output_pvs "$pvs"
}

_write_gce_conf() {
    local src_name=$(basename "$VM_SRC_IMG")
    local dst_dir=$(dirname "$VM_DST_IMG")
    local tar_path="${dst_dir}/$(_src_to_dst_name "${src_name}" ".tar.gz")"

    mv "${VM_DST_IMG}" "${VM_TMP_DIR}/disk.raw"
    tar -czf "${tar_path}" -C "${VM_TMP_DIR}" "disk.raw"
    VM_GENERATED_FILES=( "${tar_path}" )
}

_write_ovf_vmware_conf() {
    local vm_mem="${1:-$(_get_vm_opt MEM)}"
    local vm_cpus="$(_get_vm_opt CPUS)"
    local vmdk_file_size=$(du --bytes "${VM_DST_IMG}" | cut -f1)
    local vmdk_capacity=$(vmdk-convert -i "${VM_DST_IMG}" | jq .capacity)
    local ovf="$(_dst_path ".ovf")"

    sed "${BUILD_LIBRARY_DIR}/template_vmware.ovf" \
        -e "s/@@NAME@@/$(_dst_name)/g" \
        -e "s/@@VMDK_FILE_NAME@@/$(basename ${VM_DST_IMG})/g" \
        -e "s/@@VMDK_FILE_SIZE@@/${vmdk_file_size}/g" \
        -e "s/@@VMDK_CAPACITY@@/${vmdk_capacity}/g" \
        -e "s/@@NUM_CPUS@@/${vm_cpus}/g" \
        -e "s/@@MEM_SIZE@@/${vm_mem}/g" \
        > "${ovf}"

    VM_GENERATED_FILES+=( "$ovf" )
}

# If this is a bundled format generate it!
write_vm_bundle() {
    local bundle_format=$(_get_vm_opt BUNDLE_FORMAT)
    if [[ -n "${bundle_format}" ]]; then
        info "Writing ${bundle_format} bundle"
        _write_${bundle_format}_bundle "$@"
    fi
}

_write_box_bundle() {
    local box=$(_dst_path ".box")
    local json=$(_dst_path ".json")
    local image=${VM_DST_IMG}
    local provider="virtualbox"

    if [[ "${VM_IMG_TYPE}" == vagrant_vmware_fusion ]]; then
        provider="vmware_fusion"
    elif [[ "${VM_IMG_TYPE}" == vagrant_parallels ]]; then
        provider="parallels"
        image="${VM_TMP_DIR}/tmp.pvm"
        mkdir -p "${image}"
        mv "${VM_DST_IMG}" "${image}"
        mv "$(_dst_path ".pvs")" "${image}"/config.pvs
    fi

    cat > "${VM_TMP_DIR}"/box/metadata.json <<EOF
{"provider": "${provider}"}
EOF

    mv "${image}" "${VM_TMP_DIR}/box"
    tar -czf "${box}" -C "${VM_TMP_DIR}/box" .

    cat >"${json}" <<EOF
{
  "name": "flatcar-${VM_GROUP}",
  "description": "Flatcar ${VM_GROUP}",
  "versions": [{
    "version": "${FLATCAR_VERSION_ID}",
    "providers": [{
      "name": "${provider}",
      "url": "https://${BUILDCACHE_SERVER:-bincache.flatcar-linux.net}/images/${BOARD%-usr}/${FLATCAR_VERSION}/$(_dst_name ".box")",
      "checksum_type": "sha256",
      "checksum": "$(sha256sum "${box}" | awk '{print $1}')"
    }]
  }]
}
EOF
    VM_GENERATED_FILES+=( "${box}" "${json}" )
}

_write_ova_bundle() {
    local mf="$(_dst_name ".mf")"
    local vmdk="$(basename ${VM_DST_IMG})"
    local ovf=$(_dst_name ".ovf")

    cp "${VM_DST_IMG}" "${VM_TMP_DIR}/${vmdk}"
    cp "$(_dst_dir)/${ovf}" "${VM_TMP_DIR}/${ovf}"

    echo "SHA1(${vmdk})= $(sha1sum "${VM_TMP_DIR}/${vmdk}" | cut -d' ' -f1)" > "${VM_TMP_DIR}/${mf}"
    echo "SHA1(${ovf})= $(sha1sum "${VM_TMP_DIR}/${ovf}" | cut -d' ' -f1)" >> "${VM_TMP_DIR}/${mf}"

    tar -cf $(_dst_path ".ova") -C "${VM_TMP_DIR}" "${ovf}" "${mf}" "${vmdk}"

    VM_GENERATED_FILES+=( $(_dst_path ".ova") "${VM_DST_IMG}" )
}

_write_pvm_tgz_bundle() {
    local pvm="${VM_TMP_DIR}/tmp.pvm"
    local tgz=$(_dst_path ".tgz")

    mkdir -p "${pvm}"
    mv "${VM_DST_IMG}" "${pvm}"
    mv "$(_dst_path ".pvs")" "${pvm}"/config.pvs

    tar -czf "${tgz}" -C "${pvm}" .

    VM_GENERATED_FILES+=( "${tgz}" )
}

vm_cleanup() {
    info "Cleaning up temporary files"
    if mountpoint -q "${VM_TMP_ROOT}"; then
        cleanup_mounts "${VM_TMP_ROOT}"
    fi
    sudo rm -rf "${VM_TMP_DIR}"
}

print_readme() {
    local filename
    info "Files written to $(relpath "$(dirname "${VM_DST_IMG}")")"
    for filename in "${VM_GENERATED_FILES[@]}"; do
        info " - $(basename "${filename}")"
    done

    if [[ -f "${VM_README}" ]]; then
        cat "${VM_README}"
    fi
}
