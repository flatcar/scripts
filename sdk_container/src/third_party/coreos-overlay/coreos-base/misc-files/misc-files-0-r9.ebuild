# Copyright (c) 2023 The Flatcar Maintainers.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

TMPFILES_OPTIONAL=1
inherit systemd tmpfiles

DESCRIPTION='Flatcar miscellaneous files'
HOMEPAGE='https://www.flatcar.org/'

LICENSE='Apache-2.0'
SLOT='0'
KEYWORDS='amd64 arm64'

# No source directory.
S="${WORKDIR}"

declare -A CORE_BASH_SYMLINKS
CORE_BASH_SYMLINKS=(
    ['.bash_logout']='../../usr/share/flatcar/etc/skel/.bash_logout'
    ['.bash_profile']='../../usr/share/flatcar/etc/skel/.bash_profile'
    ['.bashrc']='../../usr/share/flatcar/etc/skel/.bashrc'
)

src_compile() {
    # An empty file for temporary symlink destinations under
    # /usr/share/flatcar/etc.
    touch "${T}/empty-file"
    # Generate the tmpfiles config file for bash symlinks in core home
    # directory.
    local name config config_tmp target
    config="${T}/home-core-bash-symlinks.conf"
    config_tmp="${config}.tmp"
    truncate --size 0 "${config_tmp}"
    for name in "${!CORE_BASH_SYMLINKS[@]}"; do
        target=${CORE_BASH_SYMLINKS["${name}"]}
        echo "L /home/core/${name} - core core - ${target}" >>"${config_tmp}"
    done
    LC_ALL=C sort "${config_tmp}" >"${config}"
}

src_install() {
    insinto '/usr/share/flatcar'
    # The "oems" folder should contain a file "$OEMID" for each expected OEM sysext and
    # either be empty or contain a newline-separated list of files to delete during the
    # migration (done from the initrd). The existence of the file will help old clients
    # to do the fallback download of the sysext payload in the postinstall hook.
    # The paths should use /oem instead of /usr/share/oem/ to avoid symlink resolution.
    doins -r "${FILESDIR}"/oems

    dotmpfiles "${T}/home-core-bash-symlinks.conf"
    # Ideally we would be calling systemd-tmpfiles to create the
    # symlinks, but at this point systemd may not have any info about
    # the core user. Thus we hardcode the id 500.
    dodir /home/core
    fowners 500:500 /home/core
    local name
    for name in "${!CORE_BASH_SYMLINKS[@]}"; do
        target=${CORE_BASH_SYMLINKS["${name}"]}
        link="/home/core/${name}"
        dosym "${target}" "${link}"
        fowners --no-dereference 500:500 "${link}"
    done

    # Create a symlink for Kubernetes to redirect writes from /usr/libexec/... to /var/kubernetes/...
    # (The below keepdir will result in a tmpfiles entry in base_image_var.conf)
    keepdir /var/kubernetes/kubelet-plugins/volume/exec
    dosym /var/kubernetes/kubelet-plugins/volume/exec /usr/libexec/kubernetes/kubelet-plugins/volume/exec
}
