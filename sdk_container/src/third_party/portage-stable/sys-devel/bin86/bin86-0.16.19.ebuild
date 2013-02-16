# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/bin86/bin86-0.16.19.ebuild,v 1.1 2013/01/06 18:15:41 vapier Exp $

EAPI="4"

inherit toolchain-funcs eutils

DESCRIPTION="Assembler and loader used to create kernel bootsector"
HOMEPAGE="http://www.debath.co.uk/"
SRC_URI="http://www.debath.co.uk/dev86/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86 ~x86-fbsd"
IUSE=""

src_prepare() {
	sed -i \
		-e '/^PREFIX/s:=.*:=$(DESTDIR)/usr:' \
		-e '/^MANDIR/s:)/man/man1:)/share/man/man1:' \
		-e '/^INSTALL_OPTS/s:-s::' \
		-e "/^CFLAGS/s:=.*:=${CFLAGS} -D_POSIX_SOURCE ${CPPFLAGS}:" \
		-e "/^LDFLAGS/s:=.*:=${LDFLAGS}:" \
		Makefile || die
#	epatch "${FILESDIR}"/${PN}-0.16.18-headers.patch #347817
	epatch "${FILESDIR}"/${PN}-0.16.17-amd64-build.patch
	tc-export CC
}

src_install() {
	dodir /usr/bin /usr/share/man/man1
	default
}
