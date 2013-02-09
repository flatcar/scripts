# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libj2k/libj2k-0.0.9.ebuild,v 1.4 2009/01/07 21:49:34 armin76 Exp $

DESCRIPTION="Lib for Yahoo webcam support in gaim-vv"
HOMEPAGE="http://sourceforge.net/projects/gaim-vv/"
SRC_URI="mirror://sourceforge/gaim-vv/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~ia64 ~sparc ~x86"
IUSE=""

src_install() {
	make DESTDIR=${D} install || die "make install failed"
	dodoc README
}
