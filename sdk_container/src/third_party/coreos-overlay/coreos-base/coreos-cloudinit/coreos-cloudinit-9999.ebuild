# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

COREOS_GO_PACKAGE="github.com/flatcar/coreos-cloudinit"
COREOS_GO_GO111MODULE="on"
inherit systemd toolchain-funcs udev coreos-go

DESCRIPTION="Enables a user to customize Flatcar Container Linux machines"
HOMEPAGE="https://github.com/flatcar/coreos-cloudinit"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/coreos-cloudinit.git"
	inherit git-r3
else
	EGIT_VERSION="1c1d7f4ae6b933350d7fd36e882dda170123cccc" # main
	SRC_URI="https://github.com/flatcar/coreos-cloudinit/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_VERSION}"
	KEYWORDS="amd64 arm64"
fi

LICENSE="Apache-2.0"
SLOT="0"

RDEPEND=">=sys-apps/shadow-4.1.5.1"

src_prepare() {
	coreos-go_src_prepare

	if gcc-specs-pie; then
		CGO_LDFLAGS+=" -fno-PIC"
	fi
}

src_compile() {
	GO_LDFLAGS="-X main.version=v${PV}-g${EGIT_VERSION:0:7}" || die
	coreos-go_src_compile
}

src_install() {
	dobin ${GOBIN}/coreos-cloudinit
	udev_dorules units/*.rules
	systemd_dounit units/*.mount
	systemd_dounit units/*.path
	systemd_dounit units/*.service
	systemd_dounit units/*.target
	systemd_enable_service multi-user.target system-config.target
	systemd_enable_service multi-user.target user-config.target
}
