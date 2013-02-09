# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libXcm/libXcm-0.5.1.ebuild,v 1.1 2012/06/30 07:35:41 xmw Exp $

EAPI=4

DESCRIPTION="reference implementation of the net-color spec"
HOMEPAGE="http://www.oyranos.org/libxcm/"
SRC_URI="mirror://sourceforge/oyranos/${PN}/${PN}-0.4.x/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="X doc static-libs"

RDEPEND="X? ( x11-libs/libXmu
		x11-libs/libXfixes
		x11-libs/libX11
		x11-proto/xproto )"
DEPEND="${RDEPEND}
	app-doc/doxygen"

src_configure() {
	econf --disable-silent-rules \
		$(use_with X x11) \
		$(use_enable static-libs static)
}

src_install() {
	default

	use doc && dohtml doc/html/*
}
