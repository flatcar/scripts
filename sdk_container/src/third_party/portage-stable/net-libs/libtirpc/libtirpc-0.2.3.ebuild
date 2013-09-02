# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-libs/libtirpc/libtirpc-0.2.3.ebuild,v 1.1 2013/02/18 21:56:35 vapier Exp $

EAPI="4"

inherit toolchain-funcs

DESCRIPTION="Transport Independent RPC library (SunRPC replacement)"
HOMEPAGE="http://libtirpc.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2
	mirror://gentoo/${PN}-glibc-nfs.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="kerberos static-libs"

RDEPEND="kerberos? ( net-libs/libgssglue )"
DEPEND="${RDEPEND}
	app-arch/xz-utils
	virtual/pkgconfig"

src_unpack() {
	unpack ${A}
	cp -r tirpc "${S}"/ || die
}

src_configure() {
	econf \
		$(use_enable kerberos gss) \
		$(use_enable static-libs static)
}

src_install() {
	default
	insinto /etc
	newins doc/etc_netconfig netconfig

	insinto /usr/include/tirpc
	doins -r "${WORKDIR}"/tirpc/*

	# libtirpc replaces rpc support in glibc, so we need it in /
	gen_usr_ldscript -a tirpc

	# makes sure that the linking order for nfs-utils is proper, as
	# libtool would inject a libgssglue dependency in the list.
	use static-libs || find "${ED}" -name '*.la' -delete
}
