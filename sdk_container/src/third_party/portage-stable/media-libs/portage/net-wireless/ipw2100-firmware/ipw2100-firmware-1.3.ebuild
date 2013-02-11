# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/ipw2100-firmware/ipw2100-firmware-1.3.ebuild,v 1.7 2013/01/21 22:30:06 ssuominen Exp $

inherit multilib

MY_P=${P/firmware/fw}
S=${WORKDIR}

DESCRIPTION="Firmware for the Intel PRO/Wireless 2100 3B miniPCI adapter"

HOMEPAGE="http://ipw2100.sourceforge.net/"
SRC_URI="mirror://gentoo/${MY_P}.tgz"

LICENSE="ipw2100-fw"
SLOT="${PV}"
KEYWORDS="amd64 x86"

IUSE=""
DEPEND="virtual/udev"

src_install() {
	insinto $(get_libdir)/firmware
	doins ipw2100-${PV}.fw ipw2100-${PV}-p.fw ipw2100-${PV}-i.fw

	newins LICENSE ipw2100-${PV}-LICENSE
}
