# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/ar9271-firmware/ar9271-firmware-1.3.ebuild,v 1.3 2012/12/10 07:46:12 slyfox Exp $

EAPI="3"

FIRMWARE_NAME="htc_9271.fw"

DESCRIPTION="Atheros firmware for AR9271 (ath9k_htc module)"
HOMEPAGE="http://linuxwireless.org/en/users/Drivers/ath9k_htc"
SRC_URI="http://linuxwireless.org/download/htc_fw/${PV}/${FIRMWARE_NAME} -> ${P}-${FIRMWARE_NAME}
	http://linuxwireless.org/download/htc_fw/${PV}/Changelog -> ${P}.Changelog"

LICENSE="freedist"
KEYWORDS="~amd64 ~arm ~x86"
IUSE=""
RESTRICT="binchecks strip"
SLOT="0"
DEPEND=""
RDEPEND=""

S="${WORKDIR}/${MY_P}"

src_unpack() {
	cp "${DISTDIR}"/${P}-${FIRMWARE_NAME} "${WORKDIR}"/${FIRMWARE_NAME} || die
	cp "${DISTDIR}"/${P}.Changelog "${WORKDIR}"/Changelog || die
}

src_compile() { :; }

src_install() {
	insinto /lib/firmware
	doins "${FIRMWARE_NAME}" || die

	dodoc Changelog
}
