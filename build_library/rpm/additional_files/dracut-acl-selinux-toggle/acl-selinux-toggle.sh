#!/bin/bash
# Query Azure IMDS for an "acl-node-security-profile" tag and set SELinux
# mode before switch-root. The tag value is a comma-separated list of k/v
# pairs, e.g. "selinux=enforcing,...". Runs in the initrd so SELinux is
# configured before real-root services start.

set -euo pipefail

# usrbin wrapper — access real-root userspace binaries from /sysusr/usr/bin
# with the correct library path, matching bootengine's initrd-setup-root.
function usrbin() {
  local cmd="$1"
  shift
  LD_LIBRARY_PATH=/sysusr/usr/lib64 /sysusr/usr/bin/"${cmd}" "$@"
}

echo "ACL: Starting networkd for IMDS SELinux tag check" >&2
systemctl start --quiet systemd-networkd systemd-resolved

imds_tags=""
imds_reached=0
for i in $(usrbin seq 30); do
  if imds_tags=$(usrbin curl -sf -H "Metadata:true" --noproxy "*" --max-time 5 \
    "http://169.254.169.254/metadata/instance/compute/tagsList?api-version=2021-02-01" 2>/dev/null); then
    imds_reached=1
    break
  fi
  echo "ACL: IMDS not ready, retry ${i}/30" >&2
  sleep 1
done

if [ "${imds_reached}" -ne 1 ]; then
  echo "ACL: IMDS unreachable after 30 retries" >&2
  exit 1
fi

security_profile=$(echo "${imds_tags}" | usrbin jq -r '.[] | select(.name=="acl-node-security-profile") | .value')

if [ -z "${security_profile}" ]; then
  echo "ACL: IMDS reached but no acl-node-security-profile tag set, leaving SELinux mode unchanged" >&2
  exit 0
fi

# Extract the selinux value from the comma-separated k/v list.
selinux_mode=""
IFS=',' read -ra pairs <<< "${security_profile}"
for pair in "${pairs[@]}"; do
  IFS='=' read -r key value <<< "${pair}"
  if [ "${key}" = "selinux" ]; then
    selinux_mode="${value}"
    break
  fi
done

case "${selinux_mode}" in
  permissive)
    echo "ACL: acl-node-security-profile selinux=permissive found, setting SELinux to permissive" >&2
    sed -i "s/^SELINUX=enforcing/SELINUX=permissive/" /sysroot/etc/selinux/config
    ;;
  enforcing)
    echo "ACL: acl-node-security-profile selinux=enforcing found, setting SELinux to enforcing" >&2
    sed -i "s/^SELINUX=permissive/SELINUX=enforcing/" /sysroot/etc/selinux/config
    ;;
  "")
    echo "ACL: acl-node-security-profile tag found but no selinux key present, leaving SELinux mode unchanged" >&2
    ;;
  *)
    echo "ACL: acl-node-security-profile selinux key has unrecognized value '${selinux_mode}', leaving SELinux mode unchanged" >&2
    ;;
esac
