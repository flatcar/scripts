#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# RPM-specific mangle logic for the docker-flatcar sysext.
# Called from build_library/sysext_mangle_docker-flatcar when PACKAGE_SOURCE_MODE=RPM
#
# Items that must live in the rootfs (etcd native cleanup, sysusers.d/etcd.conf,
# /usr/lib/coreos symlink) are handled by _configure_etcd_rpm in build_image_util.sh.
# This script installs Docker-dependent components into the sysext.

set -euo pipefail

rootfs="${1}"
script_root="$(cd "$(dirname "$0")/../../"; pwd)"

# ── etcd-wrapper: Docker-based etcd with sdnotify-proxy ──────────────────────
# etcd-wrapper runs etcd inside a Docker container, so it belongs in the Docker sysext.
echo ">>> NOTICE: $0: installing etcd-wrapper (Docker-based etcd)"

# Install etcd-wrapper - runs etcd in a Docker container with sdnotify-proxy.
# These files come from the Flatcar etcd-wrapper package in sdk_container.
etcd_wrapper_src="${script_root}/sdk_container/src/third_party/coreos-overlay/app-admin/etcd-wrapper/files"
etcd_version="3.5.16"
if [[ ! -d "${etcd_wrapper_src}" ]]; then
  echo ">>> ERROR: $0: etcd-wrapper source not found at ${etcd_wrapper_src}" >&2
  exit 1
fi

# etcd-wrapper script -> /usr/lib/flatcar/etcd-wrapper
mkdir -p "${rootfs}/usr/lib/flatcar"
cp "${etcd_wrapper_src}/etcd-wrapper" "${rootfs}/usr/lib/flatcar/etcd-wrapper"
chmod 0755 "${rootfs}/usr/lib/flatcar/etcd-wrapper"
# Azure Linux symlinks /etc/ssl/certs -> /etc/pki/tls/certs -> /etc/pki/ca-trust/extracted/pem
# etcd-wrapper bind-mounts /etc/ssl/certs and /usr/share/ca-certificates into the
# Docker container, but the files are symlinks to /etc/pki/ca-trust/extracted/pem/... which
# doesn't exist in the container. Add an extra bind mount so the symlinks resolve.
sed -i 's|-v ${ETCD_SSL_DIR}:/etc/ssl/certs:ro|-v /etc/pki/ca-trust/extracted/pem:/etc/pki/ca-trust/extracted/pem:ro -v ${ETCD_SSL_DIR}:/etc/ssl/certs:ro|' \
    "${rootfs}/usr/lib/flatcar/etcd-wrapper"
# NOTE: etcd-member.service and etcd-wrapper.conf are installed in the rootfs
# by _configure_etcd_rpm() in build_image_util.sh. They MUST be in the rootfs
# because Ignition needs to read etcd-member.service's [Install] section to
# create the enable symlink, and Ignition runs before sysext merge.

# CA certificates compatibility for etcd-wrapper Docker mount.
# etcd-wrapper bind-mounts /usr/share/ca-certificates:/usr/share/ca-certificates:ro
# into the Docker container. On ACL this directory doesn't exist, and Docker
# tries to mkdir it on the read-only /usr partition, causing the container to
# fail with "mkdir /usr/share/ca-certificates: read-only file system".
# Fix: create the directory in the sysext with a symlink to the ACL CA bundle.
# Above we add a bind mount for /etc/pki/ca-trust/extracted/pem so the symlink resolves.
mkdir -p "${rootfs}/usr/share/ca-certificates"
ln -sf /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem \
    "${rootfs}/usr/share/ca-certificates/ca-certificates.crt"

# ── flannel-wrapper: Docker-based flanneld ───────────────────────────────────
# flannel-wrapper runs flanneld in a Docker container (like etcd-wrapper).
echo ">>> NOTICE: $0: installing flannel-wrapper (Docker-based flanneld)"

flannel_wrapper_src="${script_root}/sdk_container/src/third_party/coreos-overlay/app-admin/flannel-wrapper/files"
flannel_version="0.14.0"
if [[ ! -d "${flannel_wrapper_src}" ]]; then
  echo ">>> ERROR: $0: flannel-wrapper source not found at ${flannel_wrapper_src}" >&2
  exit 1
fi

# flannel-wrapper script -> /usr/lib/flatcar/flannel-wrapper
# (resolves via /usr/lib/coreos -> flatcar symlink created by _configure_etcd_rpm)
cp "${flannel_wrapper_src}/flannel-wrapper" "${rootfs}/usr/lib/flatcar/flannel-wrapper"
chmod 0755 "${rootfs}/usr/lib/flatcar/flannel-wrapper"
# NOTE: flanneld.service and flannel-docker-opts.service are installed in the
# rootfs by _configure_flannel_services_rpm() in build_image_util.sh. They MUST
# be in the rootfs because Ignition needs to read their [Install] sections to
# create enable symlinks, and Ignition runs before sysext merge.

# networkd configs for flannel interfaces
cp "${flannel_wrapper_src}/50-flannel.network" "${rootfs}/usr/lib/systemd/network/50-flannel.network"
cp "${flannel_wrapper_src}/50-flannel.link" "${rootfs}/usr/lib/systemd/network/50-flannel.link"
