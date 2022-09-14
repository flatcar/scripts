# Copyright (c) 2017 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=6

CROS_WORKON_PROJECT="flatcar/update-ssh-keys"
CROS_WORKON_LOCALNAME="update-ssh-keys"
CROS_WORKON_REPO="https://github.com"

if [[ ${PV} == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
else
	CROS_WORKON_COMMIT="9c41390e2523548cd1a58d98f0ad011bd9faacb7" # v0.3.0
	KEYWORDS="amd64 arm64"
fi

inherit coreos-cargo cros-workon

DESCRIPTION="Utility for managing OpenSSH authorized public keys"
HOMEPAGE="https://github.com/flatcar-linux/update-ssh-keys"
LICENSE="Apache-2.0"
SLOT="0"

# make sure we have a new enough coreos-init that we won't conflict with the
# old bash script
RDEPEND="!<coreos-base/coreos-init-0.0.1-r152"

# sed -n 's/^"checksum \([^ ]*\) \([^ ]*\) .*/\1-\2/p' Cargo.lock
CRATES="
ansi_term-0.11.0
atty-0.2.11
base64-0.10.1
bitflags-1.0.4
block-buffer-0.7.2
block-padding-0.1.3
byte-tools-0.3.1
byteorder-1.3.1
clap-2.33.0
digest-0.8.0
error-chain-0.12.0
fake-simd-0.1.2
fs2-0.4.3
generic-array-0.12.0
libc-0.2.51
md-5-0.8.0
opaque-debug-0.2.2
openssh-keys-0.4.1
redox_syscall-0.1.53
redox_termios-0.1.1
sha2-0.8.0
strsim-0.8.0
termion-1.5.1
textwrap-0.11.0
typenum-1.10.0
unicode-width-0.1.5
users-0.8.1
vec_map-0.8.1
winapi-0.3.7
winapi-i686-pc-windows-gnu-0.4.0
winapi-x86_64-pc-windows-gnu-0.4.0
"

inherit coreos-cargo cros-workon

DESCRIPTION="Utility for managing OpenSSH authorized public keys"
HOMEPAGE="https://github.com/flatcar/update-ssh-keys"
SRC_URI="$(cargo_crate_uris ${CRATES})"

src_unpack() {
	cros-workon_src_unpack "$@"
	coreos-cargo_src_unpack "$@"
}
