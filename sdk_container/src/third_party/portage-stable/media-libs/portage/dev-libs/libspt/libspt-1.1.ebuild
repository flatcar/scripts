# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libspt/libspt-1.1.ebuild,v 1.5 2009/09/23 17:23:50 patrick Exp $

DESCRIPTION="Library for handling root privilege"
HOMEPAGE="http://www.j10n.org/libspt/index.html"
SRC_URI="http://www.j10n.org/libspt/${P}.tar.bz2"

LICENSE="BSD"

SLOT="0"
KEYWORDS="x86 alpha ppc"
IUSE=""

DEPEND=""

src_install() {

	make DESTDIR=${D} mandir=/usr/share/man install || die

	dodoc CHANGES
}
