# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/numad/numad-9999.ebuild,v 1.1 2012/06/14 05:13:03 cardoe Exp $

EAPI=4

inherit linux-info git-2

if [[ ${PV} = *9999* ]]; then
	inherit git-2
	EGIT_REPO_URI="git://git.fedorahosted.org/numad.git"
	KEYWORDS="-arm -s390"
else
	SRC_URI=""
	KEYWORDS="~amd64 ~x86 -arm -s390"
fi

DESCRIPTION="The NUMA daemon that manages application locality"
HOMEPAGE="http://fedoraproject.org/wiki/Features/numad"
#SRC_URI=""

LICENSE="LGPL-2.1"
SLOT="0"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

CONFIG_CHECK="~NUMA ~CPUSETS"

src_prepare() {
	EPATCH_FORCE=yes EPATCH_SUFFIX="patch" EPATCH_SOURCE="${FILESDIR}" \
		epatch
}

src_configure() {
	:
}

src_install() {
	emake prefix="${ED}/usr" install
}
