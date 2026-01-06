# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit python-single-r1

DESCRIPTION="emerge utilities for Flatcar developer images"
HOMEPAGE="https://github.com/flatcar/flatcar-dev-util"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/flatcar-dev-util.git"
	inherit git-r3
else
	EGIT_VERSION="00396595376d8d6a3c4b9251ba94e9de2d7a9e39" # flatcar-master
	SRC_URI="https://github.com/flatcar/flatcar-dev-util/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/flatcar-dev-util-${EGIT_VERSION}"
	KEYWORDS="amd64 arm arm64 x86"
fi

LICENSE="Apache-2.0"
SLOT="0"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	sys-apps/portage
"

src_compile() {
	:
}

src_install() {
	python_doscript emerge-gitclone
}
