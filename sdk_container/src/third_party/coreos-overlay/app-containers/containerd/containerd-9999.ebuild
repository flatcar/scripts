# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

GITHUB_URI="github.com/containerd/containerd"
COREOS_GO_PACKAGE="${GITHUB_URI}"
COREOS_GO_VERSION="go1.19"

if [[ ${PV} == *9999 ]]; then
	EGIT_REPO_URI="https://${GITHUB_URI}.git"
	inherit git-r3
else
	MY_PV="${PV/_rc/-rc.}"
	EGIT_COMMIT="v${MY_PV}"
	CONTAINERD_COMMIT="84d40840c931bd28c92dff0f70f4883b70382f01"
	SRC_URI="https://${GITHUB_URI}/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="amd64 arm64"
	inherit vcs-snapshot
fi

inherit coreos-go systemd

DESCRIPTION="A daemon to control runC"
HOMEPAGE="https://containerd.tools"

LICENSE="Apache-2.0"
SLOT="0"
IUSE="+btrfs hardened"

DEPEND="btrfs? ( sys-fs/btrfs-progs )"
RDEPEND="~app-containers/runc-1.1.9
	sys-libs/libseccomp"

S=${WORKDIR}/${P}/src/${COREOS_GO_PACKAGE}

RESTRICT="test"

src_unpack() {
	mkdir -p "${S}"
	tar --strip-components=1 -C "${S}" -xf "${DISTDIR}/${A}"
}

src_prepare() {
	coreos-go_src_prepare
	if [[ ${PV} != *9999* ]]; then
		sed -i -e "s/git describe --match.*$/echo ${PV})/"\
			-e "s/git rev-parse HEAD.*$/echo $CONTAINERD_COMMIT)/"\
			-e "s/-s -w//" \
			Makefile || die
	fi
}

src_compile() {
	local options=( $(usex btrfs "" "no_btrfs") )
	export GOPATH="${WORKDIR}/${P}" # ${PWD}/vendor
	export GO111MODULE=on
	export GOFLAGS="-v -x -mod=vendor"
	LDFLAGS=$(usex hardened '-extldflags -fno-PIC' '') emake BUILDTAGS="${options[*]}"
}

src_install() {
	dobin bin/containerd{-shim,-shim-runc-v*,} bin/ctr
	systemd_newunit "${FILESDIR}/${PN}-1.0.0.service" "${PN}.service"
	systemd_enable_service multi-user.target "${PN}.service"
	insinto /usr/share/containerd
	doins "${FILESDIR}/config.toml"
	doins "${FILESDIR}/config-cgroupfs.toml"
}
