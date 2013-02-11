# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/b43legacy-firmware/b43legacy-firmware-3.130.20.0.ebuild,v 1.2 2012/12/10 00:40:11 zerochaos Exp $

: ${B43_FIRMWARE_SRC_OBJ:=${A}}

MY_P="broadcom-wl-${PV}"
DESCRIPTION="broadcom firmware for b43legacy/bcm43xx"
HOMEPAGE="http://linuxwireless.org/en/users/Drivers/b43"
SRC_URI="http://downloads.openwrt.org/sources/wl_apsta-${PV}.o"

LICENSE="Broadcom"
SLOT=0
KEYWORDS="~amd64 ~x86"
IUSE=""
RESTRICT="mirror binchecks strip"

DEPEND=">=net-wireless/b43-fwcutter-012"
RDEPEND=""

S=${WORKDIR}

src_unpack() {
	cp "${DISTDIR}/${A}" "${WORKDIR}" || die
}

src_compile() {
	mkdir ebuild-output
	b43-fwcutter -w ebuild-output $(find -name ${B43_FIRMWARE_SRC_OBJ}) || die
}

src_install() {
	insinto /lib/firmware
	doins -r ebuild-output/* || die
}
