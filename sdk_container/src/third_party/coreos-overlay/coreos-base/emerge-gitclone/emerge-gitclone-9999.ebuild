# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_PROJECT="kinvolk/flatcar-dev-util"
CROS_WORKON_REPO="git://github.com"
CROS_WORKON_LOCALNAME="dev"
CROS_WORKON_LOCALDIR="src/platform"

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
else
	CROS_WORKON_COMMIT="c0634204f62262288735efe069c6365ed31a5c54" # flatcar-master
	KEYWORDS="amd64 arm arm64 x86"
fi

PYTHON_COMPAT=( python3_6 )

inherit cros-workon python-single-r1

DESCRIPTION="emerge utilities for Flatcar developer images"
HOMEPAGE="https://github.com/kinvolk/flatcar-dev-util/"

LICENSE="GPL-2"
SLOT="0"
IUSE=""

RDEPEND="sys-apps/portage"

src_compile() {
	echo "Nothing to compile"
}

src_install() {
	python_doscript emerge-gitclone
}
