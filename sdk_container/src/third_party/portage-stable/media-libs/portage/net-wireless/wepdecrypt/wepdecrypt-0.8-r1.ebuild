# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/wepdecrypt/wepdecrypt-0.8-r1.ebuild,v 1.3 2011/06/04 06:49:34 jlec Exp $

EAPI=4

inherit eutils

DESCRIPTION="Enhanced version of WepAttack a tool for breaking 802.11 WEP keys"
HOMEPAGE="http://wepdecrypt.sourceforge.net/"
SRC_URI="mirror://sourceforge/wepdecrypt/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="X"
RDEPEND="
	dev-libs/openssl
	net-libs/libpcap
	sys-libs/zlib
	X? ( x11-libs/fltk:1 )"
DEPEND="${RDEPEND}"

src_prepare() {
	epatch \
		"${FILESDIR}"/${P}-build.patch \
		"${FILESDIR}"/${P}-fltk.patch

	#Fix buffer size wrt bug 340148.
	epatch "${FILESDIR}/${P}-buffer.patch"

	#Fix respect for jobserver
	sed -i 's/make/$(MAKE)/g' Makefile || die "Sed failed"
}

src_configure() {
	# build system is broken and --enabled-gui doesn't work
	local myconf=""
	! use X && myconf="--disable-gui"

	econf ${myconf}
}
