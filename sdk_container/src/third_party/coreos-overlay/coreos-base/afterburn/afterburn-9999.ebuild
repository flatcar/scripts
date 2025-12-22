# Copyright (c) 2017 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# This crate is required by our patch but missing from the vendor tarball.
CRATES="hostname@0.4.2"

inherit cargo systemd

SRC_URI="${CARGO_CRATE_URIS}"
DESCRIPTION="A tool for collecting instance metadata from various providers"
HOMEPAGE="https://github.com/coreos/afterburn"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/coreos/afterburn.git"
	inherit git-r3
else
	SRC_URI+=" https://github.com/coreos/afterburn/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
		https://github.com/coreos/afterburn/releases/download/v${PV}/${P}-vendor.tar.gz"
	KEYWORDS="amd64 arm64"
	ECARGO_VENDOR="${WORKDIR}/vendor"
fi

LICENSE="Apache-2.0"
SLOT="0"

DEPEND="
	dev-libs/openssl:0=
"
RDEPEND="
	${DEPEND}
"

PATCHES=(
	"${FILESDIR}"/0001-Revert-remove-cl-legacy-feature.patch
	"${FILESDIR}"/0002-util-cmdline-Handle-the-cmdline-flags-as-list-of-sup.patch
	"${FILESDIR}"/0003-Cargo-reduce-binary-size-for-release-profile.patch
)

src_unpack() {
	if [[ ${PV} == 9999 ]]; then
		git-r3_src_unpack
		cargo_live_src_unpack
	fi
	cargo_src_unpack
}

src_compile() {
	cargo_src_compile --features cl-legacy
}

src_install() {
	cargo_src_install --features cl-legacy
	mv "${ED}"/usr/bin/afterburn "${ED}"/usr/bin/coreos-metadata || die

	systemd_dounit "${FILESDIR}"/coreos-metadata.service
	systemd_newunit "${FILESDIR}"/coreos-metadata-sshkeys.service coreos-metadata-sshkeys@.service
}

src_test() {
	cargo_src_test --features cl-legacy
}
