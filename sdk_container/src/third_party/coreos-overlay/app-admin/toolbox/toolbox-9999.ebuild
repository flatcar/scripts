# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Launches a container to bring in your favorite debugging or admin tools"
HOMEPAGE="https://github.com/flatcar/toolbox"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/toolbox.git"
	inherit git-r3
else
	EGIT_VERSION="a33dd49910b9208bcb835662308242494446a0ff" # main
	SRC_URI="https://github.com/flatcar/toolbox/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_VERSION}"
	KEYWORDS="amd64 arm64"
fi

LICENSE="Apache-2.0"
SLOT="0"

src_install() {
	dobin toolbox
}
