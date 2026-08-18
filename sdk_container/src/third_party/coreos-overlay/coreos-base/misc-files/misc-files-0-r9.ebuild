# Copyright (c) 2023 The Flatcar Maintainers.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION='Flatcar miscellaneous files'
HOMEPAGE='https://www.flatcar.org/'

LICENSE='Apache-2.0'
SLOT='0'
KEYWORDS='amd64 arm64'

# No source directory.
S="${WORKDIR}"

src_install() {
    insinto '/usr/share/flatcar'
    # The "oems" folder should contain a file "$OEMID" for each expected OEM sysext and
    # either be empty or contain a newline-separated list of files to delete during the
    # migration (done from the initrd). The existence of the file will help old clients
    # to do the fallback download of the sysext payload in the postinstall hook.
    # The paths should use /oem instead of /usr/share/oem/ to avoid symlink resolution.
    doins -r "${FILESDIR}"/oems

    # Create a symlink for Kubernetes to redirect writes from /usr/libexec/... to /var/kubernetes/...
    # (The below keepdir will result in a tmpfiles entry in base_image_var.conf)
    keepdir /var/kubernetes/kubelet-plugins/volume/exec
    dosym /var/kubernetes/kubelet-plugins/volume/exec /usr/libexec/kubernetes/kubelet-plugins/volume/exec
}
