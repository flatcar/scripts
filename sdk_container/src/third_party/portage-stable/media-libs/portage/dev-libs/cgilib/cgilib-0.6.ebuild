# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/cgilib/cgilib-0.6.ebuild,v 1.1 2008/06/06 09:53:52 pva Exp $

inherit toolchain-funcs

DESCRIPTION="A programmers library for the CGI interface"
HOMEPAGE="http://www.infodrom.org/projects/cgilib/"
SRC_URI="http://www.infodrom.org/projects/${PN}/download/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE=""

src_unpack() {
	unpack ${A}
	cd "${S}"

	sed -i "s:ar rc:$(tc-getAR) rc:" Makefile
}

src_compile() {
	emake CC="$(tc-getCC)" \
		CFLAGS="-I. -Wall ${CFLAGS}" || die "emake failed"
}

src_install() {
	insinto /usr/include
	doins cgi.h
	dolib.a libcgi.a
	doman *.[35]
	dodoc CHANGES CREDITS readme cookies.txt jumpto.c cgitest.c
}
