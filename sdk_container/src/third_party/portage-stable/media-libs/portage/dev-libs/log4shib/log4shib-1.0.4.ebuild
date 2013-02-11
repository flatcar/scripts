# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/log4shib/log4shib-1.0.4.ebuild,v 1.1 2011/09/13 14:45:11 hwoarang Exp $

EAPI="4"

DESCRIPTION="Internet2 version for OpenSAML of log4cpp logging framework"
HOMEPAGE="http://spaces.internet2.edu/display/OpenSAML/log4shib"
SRC_URI="http://shibboleth.internet2.edu/downloads/${PN}/${PV}/${P}.tar.gz"

KEYWORDS="~amd64 ~x86"
LICENSE="LGPL-2.1"
SLOT="0"
IUSE="debug doc static-libs"

DEPEND="doc? ( app-doc/doxygen )"
RDEPEND=""

src_configure() {
	econf --without-idsa \
		$(use_enable debug) \
		$(use_enable doc doxygen) \
		$(use_enable static-libs static)
}

src_install () {
	emake DESTDIR="${D}" install
	dodoc AUTHORS ChangeLog NEWS README THANKS
}
