# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/plib/plib-1.8.5.ebuild,v 1.8 2010/11/11 04:33:41 mr_bones_ Exp $

inherit flag-o-matic eutils

DESCRIPTION="multimedia library used by many games"
HOMEPAGE="http://plib.sourceforge.net/"
SRC_URI="http://plib.sourceforge.net/dist/${P}.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="alpha amd64 hppa ppc sparc x86"
IUSE=""

DEPEND="virtual/opengl"

src_unpack() {
	unpack ${A}
	# Since plib only provides static libraries, force
	# building as PIC or plib is useless to amd64/etc...
	append-flags -fPIC
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog KNOWN_BUGS NOTICE README* TODO*
}
