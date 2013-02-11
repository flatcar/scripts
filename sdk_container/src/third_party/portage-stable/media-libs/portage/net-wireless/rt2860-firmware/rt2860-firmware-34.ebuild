# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/rt2860-firmware/rt2860-firmware-34.ebuild,v 1.3 2013/01/21 22:27:01 ssuominen Exp $

EAPI="4"

DESCRIPTION="Firmware for Ralink rt2860-based WiFi adapters (rt2800pci and rt2860sta modules)"
HOMEPAGE="http://git.kernel.org/?p=linux/kernel/git/firmware/linux-firmware.git
	http://www.ralinktech.com/en/04_support/support.php?sn=501"
# Files on Ralink's website are ancient; use linux-firmware data instead.
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="ralink-firmware"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="virtual/udev"
DEPEND=""

src_install() {
	insinto /lib/firmware
	doins rt2860.bin rt3090.bin
	# The license must be installed so that we can redistribute.
	# Otherwise binpkgs or CDs wouldn't have the license.
	dodoc LICENCE.ralink-firmware.txt WHENCE
}
