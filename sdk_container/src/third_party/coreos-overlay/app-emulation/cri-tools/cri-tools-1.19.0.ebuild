# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit coreos-go

COREOS_GO_PACKAGE="github.com/kubernetes-sigs/cri-tools"
COREOS_GO_MOD="vendor"

MY_PV="v${PV/_beta/-beta.}"

EGO_PN="${COREOS_GO_PACKAGE}"
DESCRIPTION="CLI and validation tools for Kubelet Container Runtime (CRI)"
HOMEPAGE="https://github.com/kubernetes-sigs/cri-tools"
SRC_URI="https://github.com/kubernetes-sigs/cri-tools/archive/${MY_PV}.tar.gz -> ${P}.tar.gz"
LICENSE="Apache-2.0 BSD BSD-2 CC-BY-SA-4.0 ISC MIT MPL-2.0"
SLOT="0"
# Flatcar: keyword arm64
KEYWORDS="amd64 arm64"

S=${WORKDIR}/cri-tools-${PV}

DEPEND=""
RDEPEND="${DEPEND}"

src_compile() {
	# Flatcar: to optimize the binary size of crictl, make use of the existing
	# helpers provided by `coreos-go.eclass`.
	# Add "-X $(PROJECT)/pkg/version.Version=$(VERSION)" to GO_LDFLAGS,
	# as the original cri-tools Makefile does.
	# Note, we cannot run the native command like `emake crictl`, because
	# the cri-tools Makefile does not allow custom env variables like BUILDTAGS
	# or GO_LDFLAGS to be configured.
	GO_LDFLAGS="-s -w -extldflags=-Wl,-z,now,-z,relro,-z,defs "
	GO_LDFLAGS+="-X ${COREOS_GO_PACKAGE}/pkg/version.Version=${PV} "
	go_build "${COREOS_GO_PACKAGE}/cmd/crictl"
}

src_install() {
	# Flatcar: install only crictl binary
	dobin "${GOBIN}/crictl"
}
