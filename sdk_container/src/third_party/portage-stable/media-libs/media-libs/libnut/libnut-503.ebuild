# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libnut/libnut-503.ebuild,v 1.3 2009/07/31 21:31:54 chainsaw Exp $

inherit flag-o-matic

DESCRIPTION="Library and tools to create NUT multimedia files"
HOMEPAGE="http://svn.mplayerhq.hu/nut/
	http://www.nut-container.org/"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""
DEPEND=""
RDEPEND=""

src_install() {
	make PREFIX="${D}/usr" install || die "make install died"
	dodoc README docs/*
	cd "${S}/nututils"
	dobin nutindex nutmerge nutparse avireader
}
