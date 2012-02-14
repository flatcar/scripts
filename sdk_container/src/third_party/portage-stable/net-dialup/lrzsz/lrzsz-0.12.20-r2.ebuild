# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-dialup/lrzsz/lrzsz-0.12.20-r2.ebuild,v 1.9 2009/04/29 12:49:25 jer Exp $

EAPI="2"

inherit flag-o-matic eutils toolchain-funcs

DESCRIPTION="Communication package providing the X, Y, and ZMODEM file transfer protocols"
HOMEPAGE="http://www.ohse.de/uwe/software/lrzsz.html"
SRC_URI="http://www.ohse.de/uwe/releases/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE="nls"

DEPEND="nls? ( virtual/libintl )"
RDEPEND="${DEPEND}"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-makefile-smp.patch
	epatch "${FILESDIR}"/${PN}-implicit-decl.patch
}

src_configure() {
	tc-export CC
	append-flags -Wstrict-prototypes
	econf $(use_enable nls) || die "econf failed"
}

src_test() {
	#Don't use check target.
	#See bug #120748 before changing this function.
	make vcheck || die "tests failed"
}

src_install() {
	make \
		prefix="${D}/usr" \
		mandir="${D}/usr/share/man" \
		install || die "make install failed"

	local x
	for x in {r,s}{b,x,z} ; do
		dosym l${x} /usr/bin/${x}
		dosym l${x:0:1}z.1 /usr/share/man/man1/${x}.1
		[ "${x:1:1}" = "z" ] || dosym l${x:0:1}z.1 /usr/share/man/man1/l${x}.1
	done

	dodoc AUTHORS COMPATABILITY ChangeLog NEWS README* THANKS TODO
}
