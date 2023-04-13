# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
GIT_COMMIT=8659133e59
EGO_PN="github.com/docker/cli"

COREOS_GO_PACKAGE="${EGO_PN}"
COREOS_GO_VERSION="go1.18"

inherit bash-completion-r1  golang-vcs-snapshot coreos-go-depend

DESCRIPTION="the command line binary for docker"
HOMEPAGE="https://www.docker.com/"
MY_PV=${PV/_/-}
SRC_URI="https://github.com/docker/cli/archive/v${MY_PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE="hardened"

RDEPEND="!<app-emulation/docker-20.10.1"

RESTRICT="installsources strip"

S="${WORKDIR}/${P}/src/${EGO_PN}"

src_prepare() {
	default
	sed -i 's@dockerd\?\.exe@@g' contrib/completion/bash/docker || die
}

src_compile() {
	# Flatcar: override go version
	go_export

	export DISABLE_WARN_OUTSIDE_CONTAINER=1
	export GOPATH="${WORKDIR}/${P}"
	# setup CFLAGS and LDFLAGS for separate build target
	# see https://github.com/tianon/docker-overlay/pull/10
	# FLatcar: inject our own CFLAGS/LDFLAGS for torcx
	export CGO_CFLAGS="${CGO_CFLAGS} -I${SYSROOT}/usr/include"
	export CGO_LDFLAGS="${CGO_LDFLAGS} -L${SYSROOT}/usr/$(get_libdir)"
		emake \
		LDFLAGS="$(usex hardened '-extldflags -fno-PIC' '')" \
		VERSION="${PV}" \
		GITCOMMIT="${GIT_COMMIT}" \
		dynbinary

	# Flatcar: removed man page generation since they are not included in images
}

src_install() {
	dobin build/docker
	dobashcomp contrib/completion/bash/*
	bashcomp_alias docker dockerd
	insinto /usr/share/fish/vendor_completions.d/
	doins contrib/completion/fish/docker.fish
	insinto /usr/share/zsh/site-functions
	doins contrib/completion/zsh/_*
}
