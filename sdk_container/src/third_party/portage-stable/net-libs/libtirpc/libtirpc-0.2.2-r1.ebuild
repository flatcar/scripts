# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-libs/libtirpc/libtirpc-0.2.2-r1.ebuild,v 1.9 2012/05/05 02:54:24 jdhore Exp $

EAPI="3"

inherit eutils toolchain-funcs

DESCRIPTION="Transport Independent RPC library (SunRPC replacement)"
HOMEPAGE="http://libtirpc.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2
	mirror://gentoo/${PN}-glibc-nfs.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86"
IUSE="kerberos static-libs"

RDEPEND="kerberos? ( net-libs/libgssglue )"
DEPEND="${RDEPEND}
	app-arch/xz-utils
	virtual/pkgconfig"

src_unpack() {
	unpack ${A}
	cp -r tirpc "${S}"/ || die
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-0.2.1-fortify.patch
	epatch "${FILESDIR}"/${PN}-0.2.2-rpc-des-prot.patch
	> src/des_crypt.c #370713
}

src_configure() {
	econf \
		$(use_enable kerberos gss) \
		$(use_enable static-libs static)
}

src_install() {
	emake install DESTDIR="${D}" || die
	dodoc AUTHORS ChangeLog NEWS README THANKS TODO
	insinto /etc
	newins doc/etc_netconfig netconfig || die

	insinto /usr/include/tirpc
	doins -r "${WORKDIR}"/tirpc/* || die

	# libtirpc replaces rpc support in glibc, so we need it in /
	gen_usr_ldscript -a tirpc

	# makes sure that the linking order for nfs-utils is proper, as
	# libtool would inject a libgssglue dependency in the list.
	use static-libs || find "${D}" -name '*.la' -delete
}
