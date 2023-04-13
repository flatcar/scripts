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
EGIT_COMMIT="fed311f0529333efb42a289dc864d1ea9f59ebfa"

KEYWORDS="amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

src_install() {
	emake DESTDIR="${D}" install
}
