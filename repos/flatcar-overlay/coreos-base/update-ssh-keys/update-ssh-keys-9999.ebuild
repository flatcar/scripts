# Copyright (c) 2017 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/flatcar/update-ssh-keys.git"

if [[ ${PV} == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
	CRATES=""
else
	EGIT_COMMIT="2a2aa89cd6eda6202de62b8870ca50945c836c54" # flatcar-master
	KEYWORDS="amd64 arm64"

	CRATES="
		anstream@0.6.4
		anstyle@1.0.4
		anstyle-parse@0.2.2
		anstyle-query@1.0.0
		anstyle-wincon@3.0.1
		base64@0.21.5
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
		error-chain@0.12.4
		fs2@0.4.3
		generic-array@0.14.7
		libc@0.2.149
		log@0.4.20
		md-5@0.10.6
		openssh-keys@0.6.2
		proc-macro2@1.0.69
		quote@1.0.33
		sha2@0.10.8
		strsim@0.10.0
		syn@2.0.38
		thiserror@1.0.50
		thiserror-impl@1.0.50
		typenum@1.17.0
		unicode-ident@1.0.12
		utf8parse@0.2.1
		uzers@0.11.3
		version_check@0.9.4
		winapi@0.3.9
		winapi-i686-pc-windows-gnu@0.4.0
		winapi-x86_64-pc-windows-gnu@0.4.0
		windows-sys@0.48.0
		windows-targets@0.48.5
		windows_aarch64_gnullvm@0.48.5
		windows_aarch64_msvc@0.48.5
		windows_i686_gnu@0.48.5
		windows_i686_msvc@0.48.5
		windows_x86_64_gnu@0.48.5
		windows_x86_64_gnullvm@0.48.5
		windows_x86_64_msvc@0.48.5
	"

	SRC_URI="https://mirror.release.flatcar-linux.net/coreos/openssh-keys-0.5.1-alpha.0.crate"
fi

inherit cargo git-r3

DESCRIPTION="Utility for managing OpenSSH authorized public keys"
HOMEPAGE="https://github.com/flatcar/update-ssh-keys"
SRC_URI+=" ${CARGO_CRATE_URIS}"

LICENSE="Apache-2.0"
SLOT="0"

# make sure we have a new enough coreos-init that we won't conflict with the
# old bash script
RDEPEND="!<coreos-base/coreos-init-0.0.1-r152"

src_unpack() {
	git-r3_src_unpack

	if [[ ${PV} == 9999 ]]; then
		cargo_live_src_unpack
	else
		cargo_src_unpack
	fi
}
