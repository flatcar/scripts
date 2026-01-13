# Copyright (c) 2015 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

COREOS_GO_PACKAGE="github.com/flatcar/mayday"
inherit coreos-go

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/mayday.git"
	inherit git-r3
else
	EGIT_VERSION="ae784704884e85de795a56752a9a10f1ff13be15" # main
	SRC_URI="https://github.com/flatcar/mayday/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_VERSION}"
	KEYWORDS="amd64 arm64"
fi

DESCRIPTION="Tool to simplify gathering support information"
HOMEPAGE="https://github.com/flatcar/mayday"

LICENSE="Apache-2.0"
SLOT="0"

src_compile() {
	COREOS_GO_MOD=vendor go_build "${COREOS_GO_PACKAGE}"
}

src_install() {
	dobin "${GOBIN}"/mayday
	insinto /usr/share/mayday
	doins default.json
}
