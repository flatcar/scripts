# Copyright (c) 2015 The CoreOS OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools

DESCRIPTION="Flatcar Disk Utilities (e.g. cgpt)"
HOMEPAGE="https://github.com/flatcar/seismograph"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/seismograph.git"
	inherit git-r3
else
	EGIT_VERSION="231f8b31c576133f75151d34cb90890bfaf15ebe" # main
	SRC_URI="https://github.com/flatcar/seismograph/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_VERSION}"
	KEYWORDS="amd64 arm arm64 x86"
fi

LICENSE="BSD"
SLOT="0"

RDEPEND="
	sys-apps/util-linux
	sys-fs/e2fsprogs
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	virtual/pkgconfig
"

src_prepare() {
	default
	eautoreconf
}
