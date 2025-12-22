# Copyright 2025 The Flatcar Container Linux Maintainers
# Distributed under the terms of the Apache License 2.0

EAPI=8

inherit coreos-go systemd
COREOS_GO_PACKAGE="github.com/coreos/go-tspi"
COREOS_GO_GO111MODULE="off"

DESCRIPTION="Go bindings and support code for libtspi and TPM communication"
HOMEPAGE="https://github.com/google/go-tspi"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/google/go-tspi.git"
	inherit git-r3
else
	EGIT_VERSION="27182e3e7b1dfcfb398b5408a619abc4f652a38b"
	SRC_URI="https://github.com/google/go-tspi/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_VERSION}"
	KEYWORDS="amd64 arm64"
fi

LICENSE="Apache-2.0"
SLOT="0"

RDEPEND="app-crypt/trousers"
DEPEND="${RDEPEND}"

src_compile() {
	go_build "${COREOS_GO_PACKAGE}"/tpmd
	go_build "${COREOS_GO_PACKAGE}"/tpmown
}

src_install() {
	dobin "${GOBIN}"/*
	systemd_dounit "${FILESDIR}"/tpmd.service
}
