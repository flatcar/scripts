# Copyright (c) 2017 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	anstream@0.6.21
	anstyle-parse@0.2.2
	anstyle-query@1.0.0
	anstyle-wincon@3.0.11
	anstyle@1.0.4
	base64@0.21.5
	bitflags@1.3.2
	bitflags@2.4.1
	block-buffer@0.10.4
	byteorder@1.5.0
	cfg-if@1.0.0
	clap@4.4.6
	clap_builder@4.4.6
	clap_lex@0.5.1
	colorchoice@1.0.0
	cpufeatures@0.2.10
	crypto-common@0.1.6
	digest@0.10.7
	errno@0.3.5
	error-chain@0.12.4
	fastrand@2.0.1
	fs2@0.4.3
	generic-array@0.14.7
	is_terminal_polyfill@1.70.2
	lazy_static@1.4.0
	libc@0.2.149
	linux-raw-sys@0.4.10
	log@0.4.20
	md-5@0.10.6
	once_cell_polyfill@1.70.2
	openssh-keys@0.6.2
	proc-macro2@1.0.69
	quote@1.0.33
	redox_syscall@0.3.5
	rustix@0.38.20
	sha2@0.10.8
	strsim@0.10.0
	syn@2.0.38
	tempfile@3.8.0
	terminal_size@0.3.0
	thiserror-impl@1.0.50
	thiserror@1.0.50
	typenum@1.17.0
	unicode-ident@1.0.12
	utf8parse@0.2.2
	uzers@0.11.3
	version_check@0.9.4
	winapi-i686-pc-windows-gnu@0.4.0
	winapi-x86_64-pc-windows-gnu@0.4.0
	winapi@0.3.9
	windows-link@0.2.1
	windows-sys@0.48.0
	windows-sys@0.61.2
	windows-targets@0.48.5
	windows_aarch64_gnullvm@0.48.5
	windows_aarch64_msvc@0.48.5
	windows_i686_gnu@0.48.5
	windows_i686_msvc@0.48.5
	windows_x86_64_gnu@0.48.5
	windows_x86_64_gnullvm@0.48.5
	windows_x86_64_msvc@0.48.5
"

inherit cargo

DESCRIPTION="Utility for managing OpenSSH authorized public keys"
HOMEPAGE="https://github.com/flatcar/update-ssh-keys"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/update-ssh-keys.git"
	inherit git-r3
else
	EGIT_VERSION="896491a6ad5b8d4a53e8eb8191d344f723a718e6" # main
	SRC_URI="https://github.com/flatcar/update-ssh-keys/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz
		${CARGO_CRATE_URIS}"
	S="${WORKDIR}/update-ssh-keys-${EGIT_VERSION}"
	KEYWORDS="amd64 arm64"
fi

LICENSE="Apache-2.0"
SLOT="0"

src_unpack() {
	if [[ ${PV} == 9999 ]]; then
		git-r3_src_unpack
		cargo_live_src_unpack
	else
		cargo_src_unpack
	fi
}
