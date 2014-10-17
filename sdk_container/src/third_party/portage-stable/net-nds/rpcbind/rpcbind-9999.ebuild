# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-nds/rpcbind/rpcbind-9999.ebuild,v 1.11 2014/01/30 21:06:30 radhermit Exp $

EAPI="4"

inherit eutils systemd

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="git://git.infradead.org/~steved/rpcbind.git"
	inherit autotools git-r3
else
	SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"
	KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
fi

DESCRIPTION="portmap replacement which supports RPC over various protocols"
HOMEPAGE="http://sourceforge.net/projects/rpcbind/"

LICENSE="BSD"
SLOT="0"
IUSE="debug selinux tcpd warmstarts"

RDEPEND=">=net-libs/libtirpc-0.2.3
	selinux? ( sec-policy/selinux-rpcbind )
	tcpd? ( sys-apps/tcp-wrappers )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_prepare() {
	[[ ${PV} == "9999" ]] && eautoreconf
	epatch_user
}

src_configure() {
	econf \
		--bindir="${EPREFIX}"/sbin \
		--with-statedir="${EPREFIX}"/run/${PN} \
		--with-rpcuser=root \
		$(use_enable tcpd libwrap) \
		$(use_enable debug) \
		$(use_enable warmstarts)
}

src_install() {
	default

	newinitd "${FILESDIR}"/${PN}.initd ${PN}
	newconfd "${FILESDIR}"/${PN}.confd ${PN}

	systemd_dounit "${FILESDIR}"/${PN}.service
}
