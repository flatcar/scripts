# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

COREOS_GO_PACKAGE="github.com/coreos/nova-agent-watcher"
COREOS_GO_GO111MODULE="off"
inherit coreos-go

DESCRIPTION="Watches for changes from Nova and reapplies them with coreos-cloudinit"
HOMEPAGE="https://github.com/coreos/nova-agent-watcher"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/coreos/nova-agent-watcher.git"
	inherit git-r3
else
	EGIT_VERSION="f750d8e5e91a7e7e22e26c9d241d27b1b7563d70"
	SRC_URI="https://github.com/coreos/nova-agent-watcher/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/${PN}-${EGIT_VERSION}"
	KEYWORDS="amd64 arm64"
fi

LICENSE="Apache-2.0"
SLOT="0"

src_install() {
	into /oem
	dobin scripts/gentoo-to-networkd
	dobin "${GOBIN}"/nova-agent-watcher
}
