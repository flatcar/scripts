# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

COREOS_GO_PACKAGE="github.com/flatcar/locksmith"
inherit systemd coreos-go

DESCRIPTION="Reboot manager for the Flatcar update engine"
HOMEPAGE="https://github.com/flatcar/locksmith"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/locksmith.git"
	inherit git-r3
else
	EGIT_VERSION="a1cb1f901971165827d68188e9f60752c0e33c10" # flatcar-master
	SRC_URI="https://github.com/flatcar/locksmith/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_VERSION}"
	KEYWORDS="amd64 arm64"
fi

LICENSE="Apache-2.0"
SLOT="0"

src_compile() {
	COREOS_GO_MOD=vendor go_build "${COREOS_GO_PACKAGE}/locksmithctl"
}

src_install() {
	dobin "${GOBIN}"/locksmithctl
	dosym ../../../bin/locksmithctl /usr/lib/locksmith/locksmithd

	systemd_dounit systemd/locksmithd.service
	systemd_enable_service multi-user.target locksmithd.service
}
