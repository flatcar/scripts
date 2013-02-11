# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libwbxml/libwbxml-0.10.1.ebuild,v 1.5 2010/09/03 13:21:32 s4t4n Exp $

inherit cmake-utils

IUSE=""

DESCRIPTION="Library and tools to parse, encode and handle WBXML documents."
HOMEPAGE="http://libwbxml.opensync.org/"
SRC_URI="mirror://sourceforge/libwbxml/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86"

DEPEND=">=dev-libs/expat-2.0.1-r1"
RDEPEND="${DEPEND}"

src_install() {
	cmake-utils_src_install || die "installation failed"

	#Fix doc installation directory. See bug #294592
	mv "${D}/usr/share/doc/${PN}" "${D}/usr/share/doc/${PF}" || die "installation failed"
}
