# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/mapm/mapm-4.9.ebuild,v 1.6 2006/08/17 18:28:06 wormo Exp $

DESCRIPTION="Mike's Arbitrary Precision Math Library"
HOMEPAGE="http://www.tc.umn.edu/~ringx004/mapm-main.html"
SRC_URI="http://www.tc.umn.edu/~ringx004/${P}.tar.gz"

LICENSE="mapm"
SLOT="0"
KEYWORDS="x86 ppc ~sparc"
IUSE=""

DEPEND=""

S=${WORKDIR}/${PN}_${PV}

src_unpack() {
	unpack ${A}
	cd ${S}
	sed -i "s:-O2:${CFLAGS}:" make_linux_shared_lib
}

src_compile() {
	./make_linux_shared_lib || die
}

src_install() {
	dolib.so libmapm.so.0
	dosym libmapm.so.0 /usr/lib/libmapm.so

	insinto /usr/include
	doins m_apm.h

	dodoc README article.pdf algorithms.used commentary.txt \
		cpp_function.ref function.ref history.txt struct.ref
}
