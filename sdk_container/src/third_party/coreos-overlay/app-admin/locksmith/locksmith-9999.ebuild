# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

# Can't use EAPI=9 - systemd.eclass does not support it yet.
EAPI=8

inherit systemd go-module

DESCRIPTION="Reboot manager for the Flatcar update engine"
HOMEPAGE="https://github.com/flatcar/locksmith"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/locksmith.git"
	inherit git-r3
else
	EGIT_VERSION="6ea5e7c73bb83cf6c013ff191cc0646e08cb3240" # flatcar-master
	SRC_URI="https://github.com/flatcar/locksmith/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_VERSION}"
	KEYWORDS="amd64 arm64"
fi

LICENSE="Apache-2.0"
SLOT="0"

BDEPEND=">=dev-lang/go-1.26.0"

src_compile() {
	go build -o bin/locksmithctl ./locksmithctl
}

src_install() {
	dobin bin/locksmithctl
	dosym -r /usr/bin/locksmithctl /usr/lib/locksmith/locksmithd

	systemd_dounit systemd/locksmithd.service
	systemd_enable_service multi-user.target locksmithd.service
}
