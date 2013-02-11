# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libaio/libaio-0.3.109-r2.ebuild,v 1.10 2012/09/19 22:53:49 jer Exp $

EAPI="3"

inherit eutils multilib toolchain-funcs

DESCRIPTION="Asynchronous input/output library that uses the kernels native interface"
HOMEPAGE="http://www.kernel.org/pub/linux/kernel/people/andrea/libaio/ http://lse.sourceforge.net/io/aio.html"
SRC_URI="mirror://kernel/linux/libs/aio/${P}.tar.bz2"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-linux"
IUSE="static-libs"

RESTRICT="test"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-0.3.109-unify-bits-endian.patch
	epatch "${FILESDIR}"/${PN}-0.3.109-generic-arch.patch
	epatch "${FILESDIR}"/${PN}-0.3.106-build.patch
	epatch "${FILESDIR}"/${PN}-0.3.107-ar-ranlib.patch
	epatch "${FILESDIR}"/${PN}-0.3.109-install.patch
	epatch "${FILESDIR}"/${PN}-0.3.109-x32.patch
	sed -i \
		-e "/^libdir=/s:lib$:$(get_libdir):" \
		-e "/^prefix=/s:/usr:${EPREFIX}/usr:" \
		-e '/:=.*strip.*shell.*git/s:=.*:=:' \
		src/Makefile Makefile || die
}

src_configure() {
	tc-export AR CC RANLIB
}

src_test() {
	cd "${S}"/harness
	mkdir testdir
	emake check prefix="${S}/src" libdir="${S}/src" || die
}

src_install() {
	# Don't use ED for emake, src_prepare already inserts EPREFIX in the correct
	# place
	emake install DESTDIR="${D}" || die
	doman man/*
	dodoc ChangeLog TODO

	# move crap to / for multipath-tools #325355
	gen_usr_ldscript -a aio
	if ! use static-libs ; then
		rm "${ED}"usr/lib*/*.a || die
	fi

	# remove stuff provided by man-pages now
	rm "${ED}"usr/share/man/man3/{lio_listio,aio_{cancel,error,fsync,init,read,return,suspend,write}}.*
}
