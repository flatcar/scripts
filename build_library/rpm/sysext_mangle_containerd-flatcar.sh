#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# RPM-specific mangle logic for the containerd-flatcar sysext.
# Called from build_library/sysext_mangle_containerd-flatcar when PACKAGE_SOURCE_MODE=RPM.
#
# In RPM mode the sysext keeps the containerd unit and config shipped by the
# Azure Linux RPM rather than overwriting them with the Flatcar copies. The
# behaviour ACL relies on that the Azure Linux unit lacks is layered on as a
# drop-in, and the config is relocated from /etc (which sysexts cannot ship,
# systemd-sysext only merges /usr and /opt) into /usr/share.

set -euo pipefail

rootfs="${1}"
azl_config="${rootfs}/etc/containerd/config.toml"
acl_config="${rootfs}/usr/share/containerd/config.toml"
acl_cgroupfs_config="${rootfs}/usr/share/containerd/config-cgroupfs.toml"
unit="${rootfs}/usr/lib/systemd/system/containerd.service"
dropin_dir="${rootfs}/usr/lib/systemd/system/containerd.service.d"
wants_dir="${rootfs}/usr/lib/systemd/system/multi-user.target.wants"

if [[ ! -f "${unit}" ]]; then
  echo ">>> ERROR: $0: Azure Linux containerd unit not found at ${unit}" >&2
  exit 1
fi

if [[ ! -f "${azl_config}" ]]; then
  echo ">>> ERROR: $0: Azure Linux containerd config not found at ${azl_config}" >&2
  exit 1
fi

echo ">>> NOTICE: $0: installing Azure Linux containerd config with SELinux enabled"
install -Dpm 0644 "${azl_config}" "${acl_config}"

if grep -Eq '^[[:space:]]*enable_selinux[[:space:]]*=' "${acl_config}"; then
  sed -i -E 's/^([[:space:]]*)enable_selinux[[:space:]]*=.*/\1enable_selinux = true/' "${acl_config}"
elif grep -Eq '^[[:space:]]*\[plugins\."io\.containerd\.grpc\.v1\.cri"\][[:space:]]*$' "${acl_config}"; then
  sed -i -E '/^[[:space:]]*\[plugins\."io\.containerd\.grpc\.v1\.cri"\][[:space:]]*$/a\    enable_selinux = true' "${acl_config}"
else
  echo ">>> ERROR: $0: CRI plugin section not found in ${azl_config}" >&2
  exit 1
fi

# Variant selected by tests that need the cgroupfs driver instead of systemd.
if ! grep -Eq '^[[:space:]]*SystemdCgroup[[:space:]]*=' "${acl_config}"; then
  echo ">>> ERROR: $0: SystemdCgroup setting not found in ${acl_config}" >&2
  exit 1
fi

echo ">>> NOTICE: $0: generating cgroupfs containerd config"
sed -E 's/^([[:space:]]*)SystemdCgroup[[:space:]]*=.*/\1SystemdCgroup = false/' \
  "${acl_config}" > "${acl_cgroupfs_config}"
chmod 0644 "${acl_cgroupfs_config}"

# The RPM enables the unit from %post, which does not run when the payload is
# unpacked into a sysext, so create the enablement symlink here.
echo ">>> NOTICE: $0: enabling containerd.service"
mkdir -p "${wants_dir}"
ln -fs ../containerd.service "${wants_dir}/containerd.service"

echo ">>> NOTICE: $0: installing ACL drop-in for containerd.service"
mkdir -p "${dropin_dir}"
cat > "${dropin_dir}/10-acl.conf" <<'EOF'
# ACL-specific overrides on top of the Azure Linux containerd.service.
[Service]
# The Azure Linux unit runs containerd without --config, which makes it read
# /etc/containerd/config.toml -- a path a sysext cannot provide. Point it at the
# copy relocated under /usr/share instead. Going through CONTAINERD_CONFIG lets
# tests swap in config-cgroupfs.toml via their own drop-in.
Environment=CONTAINERD_CONFIG=/usr/share/containerd/config.toml
ExecStart=
ExecStart=/usr/bin/containerd --config ${CONTAINERD_CONFIG}

# containerd calls sd_notify once its socket is set up, so units ordered after
# it start against a ready daemon.
Type=notify
RestartSec=5

# docker.service expects containerd's socket at the legacy libcontainerd path.
ExecStartPre=/usr/bin/mkdir -p /run/docker/libcontainerd
ExecStartPre=/usr/bin/ln -fs /run/containerd/containerd.sock /run/docker/libcontainerd/docker-containerd.sock

# (lack of) limits from the upstream docker service unit
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
EOF
chmod 0644 "${dropin_dir}/10-acl.conf"

# systemd-sysext only merges /usr and /opt, so /etc would be dead weight.
rm -rf "${rootfs}/etc/containerd"
