# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-dns/c-ares/c-ares-1.7.4.ebuild,v 1.1 2010/12/11 09:43:37 dragonheart Exp $

EAPI="2"

DESCRIPTION="C library that resolves names asynchronously"
HOMEPAGE="http://daniel.haxx.se/projects/c-ares/"
SRC_URI="http://daniel.haxx.se/projects/c-ares/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc64-solaris"
IUSE=""

DEPEND=""
RDEPEND=""

src_configure() {
	econf --enable-shared --enable-nonblocking  --enable-symbol-hiding \
		--enable-warnings
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc RELEASE-NOTES CHANGES NEWS README*
}
