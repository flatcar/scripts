# Copyright (c) 2015 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_PROJECT="flatcar-linux/mayday"
CROS_WORKON_LOCALNAME="mayday"
CROS_WORKON_REPO="git://github.com"
COREOS_GO_PACKAGE="github.com/coreos/mayday"
inherit coreos-go cros-workon

if [[ "${PV}" == 9999 ]]; then
    KEYWORDS="~amd64 ~arm64"
else
    CROS_WORKON_COMMIT="b2b1b3cb6beed130454b3fb04b45a020997a9edd" # flatcar-master
    KEYWORDS="amd64 arm64"
fi

DESCRIPTION="mayday"
HOMEPAGE="https://github.com/coreos/mayday"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
IUSE=""

src_compile() {
	COREOS_GO_MOD=vendor go_build "${COREOS_GO_PACKAGE}"
}

src_install() {
	newbin ${GOBIN}/mayday mayday
	insinto /usr/share/mayday
	doins "${S}/default.json"
}

