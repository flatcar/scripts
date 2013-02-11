# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libbegemot/libbegemot-1.11.ebuild,v 1.4 2012/04/26 17:41:19 aballier Exp $

inherit libtool

DESCRIPTION="begemot utility function library"
HOMEPAGE="http://people.freebsd.org/~harti/"
SRC_URI="http://people.freebsd.org/~harti/${PN}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~amd64-fbsd ~x86-fbsd"
IUSE=""

DEPEND=""

src_compile() {
	elibtoolize
	econf || die "econf failed"
	emake -j1 || die "emake failed"
}

src_install() {
	einstall || die "einstall failed"

	dodoc README
}
