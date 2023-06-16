# Copyright (c) 2017 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CROS_WORKON_PROJECT="flatcar/update-ssh-keys"
CROS_WORKON_LOCALNAME="update-ssh-keys"
CROS_WORKON_REPO="https://github.com"

if [[ ${PV} == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
else
	CROS_WORKON_COMMIT="5be7dcf3415f59afb8e78d7061a854f7b0efffc9" # flatcar-master
	KEYWORDS="amd64 arm64"
fi

PATCHES=(
    "${FILESDIR}"/0001-eclass-trick.patch
)

# sed -n 's/^"checksum \([^ ]*\) \([^ ]*\) .*/\1-\2/p' Cargo.lock
CRATES="
ansi_term-0.12.1
atty-0.2.14
base64-0.13.1
bitflags-1.3.2
block-buffer-0.10.3
byteorder-1.4.3
cfg-if-1.0.0
clap-2.34.0
cpufeatures-0.2.5
crypto-common-0.1.6
digest-0.10.5
error-chain-0.12.4
fs2-0.4.3
generic-array-0.14.6
hermit-abi-0.1.19
libc-0.2.137
md-5-0.10.5
openssh-keys-0.5.1-alpha.0
proc-macro2-1.0.47
quote-1.0.21
sha2-0.10.6
strsim-0.8.0
syn-1.0.103
textwrap-0.11.0
thiserror-1.0.37
thiserror-impl-1.0.37
typenum-1.15.0
unicode-ident-1.0.5
unicode-width-0.1.10
users-0.9.1
vec_map-0.8.2
version_check-0.9.4
winapi-0.3.9
winapi-i686-pc-windows-gnu-0.4.0
winapi-x86_64-pc-windows-gnu-0.4.0
"

inherit coreos-cargo cros-workon

DESCRIPTION="Utility for managing OpenSSH authorized public keys"
HOMEPAGE="https://github.com/flatcar/update-ssh-keys"
SRC_URI="https://mirror.release.flatcar-linux.net/coreos/openssh-keys-0.5.1-alpha.0.crate -> openssh-keys-0.5.1-alpha.0.crate $(cargo_crate_uris ${CRATES})"

LICENSE="Apache-2.0"
SLOT="0"

# make sure we have a new enough coreos-init that we won't conflict with the
# old bash script
RDEPEND="!<coreos-base/coreos-init-0.0.1-r152"

src_unpack() {
	cros-workon_src_unpack "$@"
	coreos-cargo_src_unpack "$@"
}
