# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libdvdread/libdvdread-9999.ebuild,v 1.4 2011/10/10 22:57:36 beandog Exp $

EAPI=4
WANT_AUTOCONF=2.5

inherit autotools libtool multilib subversion

DESCRIPTION="Library for DVD navigation tools"
HOMEPAGE="http://dvdnav.mplayerhq.hu/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="+css"

ESVN_REPO_URI="svn://svn.mplayerhq.hu/dvdnav/trunk/libdvdread"
ESVN_PROJECT="libdvdread"

DOCS=( AUTHORS DEVELOPMENT-POLICY.txt ChangeLog TODO README )

src_prepare() {
	subversion_src_prepare
	elibtoolize
	eautoreconf
}

src_install() {
	default
	rm -f "${ED}"usr/lib*/${PN}.la
}
