EXTRA_SYSEXTS=(
  zfs:sys-fs/zfs
  podman:app-containers/podman,net-misc/passt
  python:dev-lang/python,dev-python/pip
)

_get_unversioned_sysext_packages_unsorted() {
  for sysext in "${EXTRA_SYSEXTS[@]}"; do
    IFS=":" read -r _ PACKAGE_ATOMS _ <<< "$sysext"

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
