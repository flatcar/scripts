# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-db/m17n-contrib/m17n-contrib-1.1.12.ebuild,v 1.1 2011/04/04 01:12:21 flameeyes Exp $

EAPI=4

DESCRIPTION="Contribution database for the m17n library"
HOMEPAGE="http://www.m17n.org/m17n-lib/"
SRC_URI="http://www.m17n.org/m17n-lib-download/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="dev-db/m17n-db"

src_configure() {
	# force the script not to test for m17n presence, trust Portage
	# dependency handling.
	export HAVE_M17N_DB=yes

	econf
}

src_install() {
	emake DESTDIR="${D}" install || die

	dodoc AUTHORS ChangeLog NEWS README
}
