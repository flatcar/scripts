# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/rtl8192su-firmware/rtl8192su-firmware-2.6.0001.0320.2009.ebuild,v 1.1 2010/12/10 22:41:24 vapier Exp $

EAPI="3"

DESCRIPTION="RTL8191SU wireless chipset firmware"
HOMEPAGE="http://www.realtek.com.tw/"
SRC_URI="http://www.getnet.eu/data/Driver/GN-621U/Linux%20Driver.rar -> ${P}.rar"

LICENSE="freedist"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="app-arch/unrar"
RDEPEND=""

S="${WORKDIR}/Linux Driver/firmware/RTL8192SU"

src_install() {
	insinto /lib/firmware/RTL8192SU
	doins *.bin || die
}
