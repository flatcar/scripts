# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

COREOS_GO_PACKAGE="github.com/flatcar/sdnotify-proxy"
COREOS_GO_GO111MODULE="off"
inherit coreos-go

DESCRIPTION="Hack to allow Docker containers to use sd_notify"
HOMEPAGE="https://github.com/flatcar/sdnotify-proxy"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/sdnotify-proxy.git"
	inherit git-r3
else
	EGIT_VERSION="0f8ef1aa86c59fc6d54eadaffb248feaccd1018b" # main
	SRC_URI="https://github.com/flatcar/sdnotify-proxy/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_VERSION}"
	KEYWORDS="amd64 arm64"
fi

LICENSE="Apache-2.0"
SLOT="0"

src_install() {
	exeinto /usr/libexec
	doexe "${GOBIN}"/sdnotify-proxy
}
