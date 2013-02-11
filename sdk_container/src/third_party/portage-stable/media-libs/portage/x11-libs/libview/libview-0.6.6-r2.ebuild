# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libview/libview-0.6.6-r2.ebuild,v 1.2 2012/05/05 03:52:28 jdhore Exp $

EAPI=3

inherit autotools eutils gnome2

DESCRIPTION="VMware's Incredibly Exciting Widgets"
HOMEPAGE="http://view.sourceforge.net"
SRC_URI="mirror://sourceforge/view/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="static-libs"

RDEPEND=">=x11-libs/gtk+-2.4.0:2
		 dev-cpp/gtkmm:2.4"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

G2CONF="--enable-deprecated"

src_unpack() {
	gnome2_src_unpack
}

src_prepare() {
	# Fix the pkgconfig file
	epatch "${FILESDIR}"/${PN}-0.5.6-pcfix.patch
	eautoreconf -i
}
src_configure() {
	econf \
		--enable-deprecated \
		$(use_enable static-libs static)
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog NEWS

	find "${ED}" -name '*.la' -delete
}
