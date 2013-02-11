# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/dircproxy/dircproxy-1.1.0-r2.ebuild,v 1.3 2009/03/09 04:22:40 mr_bones_ Exp $

inherit eutils

DESCRIPTION="an IRC proxy server"
HOMEPAGE="http://code.google.com/p/dircproxy"
SRC_URI="http://dircproxy.googlecode.com/files/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~ppc ~sparc ~x86"
IUSE=""

src_unpack() {
	unpack ${A}
	cd ${S}

	epatch "${FILESDIR}/${PV}-less-lag-on-attach.patch"
	epatch "${FILESDIR}/${PN}-gcc4.patch"
	epatch "${FILESDIR}/1.0.5-CVE-2007-5226.patch"
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"
	dodoc AUTHORS ChangeLog FAQ NEWS PROTOCOL README* INSTALL
}
