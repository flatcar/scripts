# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_PROJECT="kinvolk/updateservicectl"
CROS_WORKON_LOCALNAME="updateservicectl"
CROS_WORKON_REPO="https://github.com"
COREOS_GO_PACKAGE="github.com/kinvolk/updateservicectl"
COREOS_GO_GO111MODULE="on"
inherit cros-workon coreos-go

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
else
	CROS_WORKON_COMMIT="6a4ff4ca879082c07353dd379439c437cbe27e18" # main
	KEYWORDS="amd64 arm64"
fi

DESCRIPTION="CoreUpdate Management CLI"
HOMEPAGE="https://github.com/kinvolk/updateservicectl"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
IUSE=""

RDEPEND="!app-admin/updatectl"

src_prepare() {
	coreos-go_src_prepare
	GOPATH+=":${S}/Godeps/_workspace"
}
