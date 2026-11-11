#!/usr/bin/env bash
# Freeze /etc into /usr/share/flatcar/etc and the signed default confext.
. "${SRCDIR}/lib/postinst.sh"

if [[ $(find "${root_fs_dir}/usr/share/flatcar/etc" -size +0 ! -type d 2>/dev/null | wc -l) -gt 0 ]]; then
  die "Unexpected non-empty files in ${root_fs_dir}/usr/share/flatcar/etc"
fi
# Backwards-compat symlinks still target this folder, so we can't drop it.
rm -rf "${root_fs_dir}/usr/share/flatcar/etc"
cp -a "${root_fs_dir}/etc" "${root_fs_dir}/usr/share/flatcar/etc"
# Verity-signed default confext: the refresh recognises it and skips re-setup
# on the final boot.
rm -rf "${root_fs_dir}/usr/lib/confexts/00-flatcar-default"
mkdir -p "${root_fs_dir}/usr/lib/confexts/00-flatcar-default"
# Do a copy because we keep /etc for the flatcar (.tar) container and the developer container
cp -a "${root_fs_dir}/etc" "${root_fs_dir}/usr/lib/confexts/00-flatcar-default/etc"
mkdir -p "${root_fs_dir}/usr/lib/confexts/00-flatcar-default/etc/extension-release.d/"
echo ID=_any | tee "${root_fs_dir}/usr/lib/confexts/00-flatcar-default/etc/extension-release.d/extension-release.00-flatcar-default" > /dev/null

# Same key as the sysexts, as in finish_image(); mkosi installs the cert into
# /usr/lib/verity.d.
verity_key="$(jq -r '.VerityKey // empty' "${MKOSI_CONFIG}")"
verity_cert="$(jq -r '.VerityCertificate // empty' "${MKOSI_CONFIG}")"
[[ -n "${verity_key}" && -n "${verity_cert}" ]] || die "VerityKey= and VerityCertificate= must be set to sign the default confext"
[[ "$(jq -r '.VerityKeySource.Type' "${MKOSI_CONFIG}")" == file ]] || die "VerityKeySource= must be a file to sign the default confext"
systemd-repart \
  --make-ddi=confext \
  --private-key="${verity_key}" \
  --certificate="${verity_cert}" \
  --copy-source="${root_fs_dir}/usr/lib/confexts/00-flatcar-default" \
  "${root_fs_dir}/usr/lib/confexts/00-flatcar-default.raw"
rm -rf "${root_fs_dir}/usr/lib/confexts/00-flatcar-default"
