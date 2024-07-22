# Copyright (c) 2015 The CoreOS OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
EGIT_REPO_URI="https://github.com/flatcar/seismograph.git"

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
else
	EGIT_COMMIT="0d57463de18df81741375d628852c521542b6836" # flatcar-master
	KEYWORDS="amd64 arm arm64 x86"
fi

inherit autotools git-r3

DESCRIPTION="CoreOS Disk Utilities (e.g. cgpt)"
LICENSE="BSD"
SLOT="0"
IUSE=""

RDEPEND="
	sys-apps/util-linux
	sys-fs/e2fsprogs
"
DEPEND="${RDEPEND}"

src_prepare() {
	default
	eautoreconf
}
