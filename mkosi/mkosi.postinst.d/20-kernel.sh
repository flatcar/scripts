#!/usr/bin/env bash
# Kernel to the /boot partition as the A slot.
. "${SRCDIR}/lib/postinst.sh"

mkdir -p "${root_fs_dir}/boot/flatcar/"
cp "${root_fs_dir}/usr/boot/vmlinuz" \
     "${root_fs_dir}/boot/flatcar/vmlinuz-a"
rm "${root_fs_dir}/usr/boot/vmlinuz"*

# coreos-kernel and coreos-modules build separate vmlinuxes; if their BTF
# diverges, the kernel refuses every module (BTF: -40) and boot fails.
btf_tmp="$(mktemp -d)"
"/build/${BOARD}/usr/src/linux/scripts/extract-vmlinux" \
    "${root_fs_dir}/boot/flatcar/vmlinuz-a" > "${btf_tmp}/vmlinux"
xz -dc "${root_fs_dir}"/usr/lib/modules/*/kernel/lib/zstd/zstd_compress.ko.xz > "${btf_tmp}/m.ko"
if ! pahole --btf_base "${btf_tmp}/vmlinux" -F btf "${btf_tmp}/m.ko" >/dev/null; then
  die "Module BTF does not match vmlinuz-a: rebuild coreos-modules and coreos-kernel together"
fi
rm -rf "${btf_tmp}"
