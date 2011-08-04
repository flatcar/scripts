# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-libs/libtirpc/libtirpc-0.2.0.ebuild,v 1.4 2009/05/30 21:28:12 vapier Exp $

inherit eutils

DESCRIPTION="Transport Independent RPC library (SunRPC replacement)"
HOMEPAGE="http://libtirpc.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="kerberos"

DEPEND="kerberos? ( net-libs/libgssglue )"
RDEPEND=${DEPEND}

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${P}-hppa-float.patch
	epatch "${FILESDIR}"/${P}-no-gss.patch
}

src_compile() {
	econf $(use_enable kerberos gss) || die
	emake || die
}

src_install() {
	emake install DESTDIR="${D}" || die
	dodoc AUTHORS ChangeLog NEWS README THANKS TODO
	insinto /etc
	newins doc/etc_netconfig netconfig || die
}
