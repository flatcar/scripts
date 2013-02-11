# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/bluez-firmware/bluez-firmware-1.2.ebuild,v 1.4 2008/06/02 06:16:17 jer Exp $

DESCRIPTION="Firmware for Broadcom BCM203x and STLC2300 Bluetooth chips."
HOMEPAGE="http://bluez.sourceforge.net/"
SRC_URI="http://bluez.sourceforge.net/download/${P}.tar.gz"

LICENSE="as-is"
SLOT="0"
KEYWORDS="~amd64 hppa ~ppc ~x86"

IUSE=""
DEPEND=""

src_compile() {
	econf --libdir=/lib || die "econf failed"
}

src_install() {
	make DESTDIR="${D}" install || die "make install failed"

	dodoc AUTHORS ChangeLog README
}
