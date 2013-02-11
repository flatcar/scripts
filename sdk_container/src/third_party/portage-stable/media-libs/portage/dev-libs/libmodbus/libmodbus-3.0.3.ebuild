# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libmodbus/libmodbus-3.0.3.ebuild,v 1.1 2012/06/11 09:46:46 xmw Exp $

EAPI=4

DESCRIPTION="Modbus library which supports RTU communication over a serial line or a TCP link"
HOMEPAGE="http://www.libmodbus.org/"
SRC_URI="http://github.com/downloads/stephane/libmodbus/${P}.tar.gz"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="static-libs"

src_configure() {
	econf \
		--disable-silent-rules \
		$(use_enable static-libs static)
}

src_install() {
	emake install DESTDIR="${D}"
	dodoc AUTHORS MIGRATION NEWS README.rst
	use static-libs || rm "${D}"/usr/*/libmodbus.la
}
