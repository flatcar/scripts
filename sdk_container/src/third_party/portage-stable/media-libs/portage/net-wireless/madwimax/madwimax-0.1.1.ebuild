# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/madwimax/madwimax-0.1.1.ebuild,v 1.5 2012/05/04 06:41:54 jdhore Exp $

EAPI="3"

inherit autotools linux-info

DESCRIPTION="A reverse-engineered Linux driver for mobile WiMAX devices based on Samsung CMC-730 chip."
HOMEPAGE="http://code.google.com/p/madwimax/"
SRC_URI="http://madwimax.googlecode.com/files/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="doc"

RDEPEND="virtual/libusb:1"
DEPEND="${RDEPEND}
		virtual/pkgconfig
		doc? (
			app-text/asciidoc
			app-text/docbook2X
		)"
CONFIG_CHECK="~TUN"

src_prepare() {
	sed -i -e "s:\(for name in docbook2\)x-man:\1man\.pl:" configure.ac || die
	eautoreconf
}

src_configure() {
	if ! use doc; then
		myconf="--without-man-pages"
	fi
	econf ${myconf} || die "econf failed"
}

src_install() {
	emake DESTDIR="${D}" install || die
	mv "${D}"/etc/udev/rules.d/{z,}60_madwimax.rules || die
	dodoc README
}
