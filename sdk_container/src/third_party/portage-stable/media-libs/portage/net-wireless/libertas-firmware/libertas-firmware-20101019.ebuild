# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/libertas-firmware/libertas-firmware-20101019.ebuild,v 1.1 2010/10/19 20:35:30 dilfridge Exp $

inherit multilib

MY_P=${P/-firmware/}
MY_PN=${PN/-firmware/}

DESCRIPTION="Firmware for the Marvell Libertas wlan chipsets (OLPC, GuruPlug)"

HOMEPAGE="http://git.kernel.org/?p=linux/kernel/git/dwmw2/linux-firmware.git;a=tree;f=libertas;hb=HEAD"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="libertas-fw"
KEYWORDS="~arm"

IUSE=""
DEPEND=""
RDEPEND=""
SLOT=0

S=${WORKDIR}/${MY_PN}

src_install() {
	insinto $(get_libdir)/firmware
	doins *.bin || die
}
