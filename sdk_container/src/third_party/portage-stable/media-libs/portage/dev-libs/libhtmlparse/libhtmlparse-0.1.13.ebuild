# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libhtmlparse/libhtmlparse-0.1.13.ebuild,v 1.3 2012/11/02 10:58:06 pinkbyte Exp $

DESCRIPTION="HTML parsing library. It takes HTML tags, text, and calls callbacks for each type of token"
HOMEPAGE="http://msalem.translator.cx/libhtmlparse.html"
SRC_URI="http://msalem.translator.cx/dist/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="x86"
IUSE=""

RDEPEND="virtual/libc"
DEPEND="${RDEPEND}"

src_unpack() {
	cd "${WORKDIR}"
	# for some reason, we get a "this does not look like a tar archive" error
	# but the following works... go figure.
	gunzip -c "${DISTDIR}"/${P}.tar.gz > ${P}.tar
	tar xf ${P}.tar || die "failed to unpack ${P}.tar"
	rm ${P}.tar
}

src_install() {
	make DESTDIR="${D}" install || die "make install failed"
	dodoc AUTHORS BUGS INSTALL ChangeLog NEWS README TODO
}
