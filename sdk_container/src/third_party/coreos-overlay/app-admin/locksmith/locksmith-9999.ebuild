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
	EGIT_VERSION="ec045e63f89b86b6c8ba0c61591d6e13f3e16362" # krnowak/deps-bump
	SRC_URI="https://github.com/flatcar/locksmith/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_VERSION}"
	KEYWORDS="amd64 arm64"
fi

LICENSE="Apache-2.0"
SLOT="0"

src_compile() {
	go build -o bin/locksmithctl ./locksmithctl
}

# Drop it when we switch to EAPI 9.
src_configure() {
	default
	go-module_src_configure
}

src_install() {
	dobin bin/locksmithctl
	dosym -r /usr/bin/locksmithctl /usr/lib/locksmith/locksmithd

	systemd_dounit systemd/locksmithd.service
	systemd_enable_service multi-user.target locksmithd.service
}
