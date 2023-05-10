# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
EGO_PN=github.com/moby/libnetwork
GIT_COMMIT=05b93e0d3a95952f70c113b0bc5bdb538d7afdd7
inherit golang-vcs-snapshot

# Flatcar: Add coreos go goo.
COREOS_GO_PACKAGE="${EGO_PN}"
COREOS_GO_VERSION="go1.18"
COREOS_GO_GO111MODULE="off"

inherit coreos-go

DESCRIPTION="Docker container networking"
HOMEPAGE="https://github.com/docker/libnetwork"
SRC_URI="https://github.com/moby/libnetwork/archive/${GIT_COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 ~arm arm64 ppc64 ~riscv ~x86"

S=${WORKDIR}/${P}/src/${EGO_PN}

# needs dockerd
RESTRICT="strip test"

# Flatcar: Rewrite src_compile
src_compile() {
	go_build "${COREOS_GO_PACKAGE}/cmd/proxy"
}

# Flatcar: Rewrite src_install
src_install() {
	dodoc README.md CHANGELOG.md
	newbin "${GOBIN}"/proxy docker-proxy
}
