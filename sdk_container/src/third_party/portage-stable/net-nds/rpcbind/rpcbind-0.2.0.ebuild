# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-nds/rpcbind/rpcbind-0.2.0.ebuild,v 1.11 2011/09/02 20:10:55 vapier Exp $

EAPI="2"

inherit autotools
if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="git://git.infradead.org/~steved/rpcbind.git"
	inherit autotools git
	SRC_URI=""
	#KEYWORDS=""
else
	SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"
	KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86"
fi

DESCRIPTION="portmap replacement which supports RPC over various protocols"
HOMEPAGE="http://sourceforge.net/projects/rpcbind/"

LICENSE="BSD"
SLOT="0"
IUSE=""

RDEPEND="net-libs/libtirpc"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_prepare() {
	if [[ ${PV} == "9999" ]] ; then
		eautoreconf
	else
		epatch "${FILESDIR}"/${P}-pkgconfig.patch
		eautoreconf
	fi
}

src_configure() {
	econf --bindir=/sbin
}

src_install() {
	emake DESTDIR="${D}" install || die
	doman man/rpc{bind,info}.8
	dodoc AUTHORS ChangeLog NEWS README
	newinitd "${FILESDIR}"/rpcbind.initd rpcbind || die
	newconfd "${FILESDIR}"/rpcbind.confd rpcbind || die
}
