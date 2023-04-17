# Copyright 2021-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

# Flatcar: remove bash-completion, inherit coreos-go
inherit go-module coreos-go

COREOS_GO_VERSION="go1.19"
COREOS_GO_PACKAGE="github.com/kubernetes-sigs/cri-tools"
COREOS_GO_MOD="vendor"

MY_PV="v${PV/_beta/-beta.}"

EGO_PN="${COREOS_GO_PACKAGE}"
DESCRIPTION="CLI and validation tools for Kubelet Container Runtime (CRI)"
HOMEPAGE="https://github.com/kubernetes-sigs/cri-tools"
SRC_URI="https://github.com/kubernetes-sigs/cri-tools/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0 BSD BSD-2 CC-BY-SA-4.0 ISC MIT MPL-2.0"
SLOT="0"
# Flatcar: keyword arm64
KEYWORDS="amd64 arm64"

S=${WORKDIR}/cri-tools-${PV}

RESTRICT+=" test"

src_compile() {
	# Flatcar: make use of the existing helpers provided by `coreos-go.eclass`.
	# To optimize the binary size of crictl, add "-X" to GO_LDFLAGS,
	# like "-X $(PROJECT)/pkg/version.Version=$(VERSION)" in the original
	# Makefile of cri-tools. We cannot follow way of Gentoo ebuilds like `emake`,
	# because Makefile of cri-tools does not allow users to pass in ${GOARCH}.
	# Remove shell completions.
	GO_LDFLAGS="-s -w -extldflags=-Wl,-z,now,-z,relro,-z,defs "
	GO_LDFLAGS+="-X ${COREOS_GO_PACKAGE}/pkg/version.Version=${PV} "
	go_build "${COREOS_GO_PACKAGE}/cmd/crictl"
}

src_install() {
	# Flatcar: install only crictl binary, remove shell completions.
	dobin "${GOBIN}/crictl"

	dodoc -r docs {README,RELEASE,CHANGELOG,CONTRIBUTING}.md
}
