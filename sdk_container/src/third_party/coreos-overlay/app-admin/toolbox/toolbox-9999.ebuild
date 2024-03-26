# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_PROJECT="flatcar/toolbox"
CROS_WORKON_LOCALNAME="toolbox"
CROS_WORKON_REPO="https://github.com"

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
else
	CROS_WORKON_COMMIT="fce9ba2bbd55e1835af72952bfbb7aed6be75606" # flatcar-master
	KEYWORDS="amd64 arm64"
fi

inherit cros-workon

DESCRIPTION="toolbox"
HOMEPAGE="https://github.com/flatcar/toolbox"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
IUSE=""

src_install() {
	dobin ${S}/toolbox
}
