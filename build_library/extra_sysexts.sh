# String format:
#
# name | packages to install | USE flags | allowed architectures
#
# packages to install - a comma-separated list of packages to install, can specify a slot too
#
# USE flags - USE flags passed as an environment variable to emerge; optional, defaults to nothing
#
# allowed architectures - optional, defaults to all the architectures
EXTRA_SYSEXTS=(
  "incus|app-containers/incus"
  "nvidia-drivers-535|x11-drivers/nvidia-drivers:0/535|-kernel-open persistenced|amd64"
  "nvidia-drivers-535-open|x11-drivers/nvidia-drivers:0/535|kernel-open persistenced|amd64"
  "nvidia-drivers-550|x11-drivers/old-nvidia-drivers:0/550|-kernel-open persistenced|amd64"
  "nvidia-drivers-550-open|x11-drivers/old-nvidia-drivers:0/550|kernel-open persistenced|amd64"
  "nvidia-drivers-570|x11-drivers/nvidia-drivers:0/570|-kernel-open persistenced|amd64"
  "nvidia-drivers-570-open|x11-drivers/nvidia-drivers:0/570|kernel-open persistenced|amd64"
  "overlaybd|sys-fs/overlaybd,app-containers/accelerated-container-image"
  "podman|app-containers/podman,net-misc/passt"
  "python|dev-lang/python,dev-python/pip"
  # Force installing libselinux and libsemanage - they are only partially installed in prod images
  "selinux|sys-apps/policycoreutils,app-admin/setools,sys-libs/libselinux,sys-libs/libsemanage"
  "zfs|sys-fs/zfs"
)

_get_unversioned_sysext_packages_unsorted() {
  for sysext in "${EXTRA_SYSEXTS[@]}"; do
    IFS="|" read -r _ PACKAGE_ATOMS _ <<< "$sysext"

    IFS=,
    for atom in $PACKAGE_ATOMS; do
       qatom "$atom" -F "%{CATEGORY}/%{PN}"
    done
    unset IFS
  done
}

get_unversioned_sysext_packages() {
  _get_unversioned_sysext_packages_unsorted | sort | uniq
}
