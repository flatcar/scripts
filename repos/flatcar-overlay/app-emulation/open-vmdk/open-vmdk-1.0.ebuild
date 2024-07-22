# Copyright 2014 VMware
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7

inherit git-r3

DESCRIPTION="Tool to convert vmdk to an ova file"
HOMEPAGE="https://github.com/vmware/open-vmdk"
LICENSE="Apache-2.0"
SLOT="0"

EGIT_REPO_URI="https://github.com/vmware/open-vmdk"
EGIT_BRANCH="master"
EGIT_COMMIT="8349c98ec8a617f5658b70d7de7d7d2830e18eaf"

KEYWORDS="amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

PATCHES=(
)

src_install() {
	emake DESTDIR="${D}" install
}
