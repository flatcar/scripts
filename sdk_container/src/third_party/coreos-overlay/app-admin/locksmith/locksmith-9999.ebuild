# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
EGIT_REPO_URI="https://github.com/flatcar/locksmith.git"
COREOS_GO_PACKAGE="github.com/flatcar/locksmith"
inherit git-r3 systemd coreos-go

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
else
	EGIT_COMMIT="ee644fc60a32af5fbc4e83c64fcc7ca0eadb9e3f" # flatcar-master
	KEYWORDS="amd64 arm64"
fi

DESCRIPTION="locksmith"
HOMEPAGE="https://github.com/flatcar/locksmith"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
IUSE=""

src_compile() {
	COREOS_GO_MOD=vendor go_build "${COREOS_GO_PACKAGE}/locksmithctl"
}

src_install() {
	dobin ${GOBIN}/locksmithctl
	dodir /usr/lib/locksmith
	dosym ../../../bin/locksmithctl /usr/lib/locksmith/locksmithd

	systemd_dounit "${S}"/systemd/locksmithd.service
	systemd_enable_service multi-user.target locksmithd.service
}
