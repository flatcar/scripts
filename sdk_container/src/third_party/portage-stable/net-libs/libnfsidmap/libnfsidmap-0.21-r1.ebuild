# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-libs/libnfsidmap/libnfsidmap-0.21-r1.ebuild,v 1.13 2012/05/21 19:13:27 xarthisius Exp $

inherit autotools eutils

DESCRIPTION="NFSv4 ID <-> name mapping library"
HOMEPAGE="http://www.citi.umich.edu/projects/nfsv4/linux/"
SRC_URI="http://www.citi.umich.edu/projects/nfsv4/linux/libnfsidmap/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86"
IUSE="ldap"

DEPEND="ldap? ( net-nds/openldap )"
RDEPEND="${DEPEND}
	!<net-fs/nfs-utils-1.1.4
	!net-fs/idmapd"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${PN}-0.19-getgrouplist.patch #169909
	epatch "${FILESDIR}"/${PN}-0.21-headers.patch
	eautoreconf
}

src_compile() {
	econf $(use_enable ldap) || die
	emake || die
}

src_install() {
	emake install DESTDIR="${D}" || die
	insinto /etc
	doins idmapd.conf || die
	dodoc AUTHORS ChangeLog NEWS README
}
