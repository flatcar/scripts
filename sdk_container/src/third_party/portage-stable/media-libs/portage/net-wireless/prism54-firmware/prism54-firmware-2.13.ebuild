# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/prism54-firmware/prism54-firmware-2.13.ebuild,v 1.8 2013/01/21 22:27:52 ssuominen Exp $

EAPI="4"

inherit eutils

DESCRIPTION="firmware for Intersil Prism GT / Prism Duette (including USB) wireless chipsets"
HOMEPAGE="http://wireless.kernel.org/en/users/Drivers/p54"
SRC_URI="http://daemonizer.de/prism54/prism54-fw/fw-softmac/2.13.12.0.arm
	http://daemonizer.de/prism54/prism54-fw/fw-usb/2.13.1.0.lm86.arm
	http://daemonizer.de/prism54/prism54-fw/fw-usb/2.13.24.0.lm87.arm
	http://daemonizer.de/prism54/prism54-fw/stlc4560/2.13.12.0.a.5.2.arm"

LICENSE="as-is"
SLOT="1"
KEYWORDS="amd64 ppc x86"
IUSE=""
RESTRICT="mirror"

RDEPEND="virtual/udev"

S=${WORKDIR}

src_unpack() { :; }

src_install() {
	dodir /lib/firmware
	insinto /lib/firmware
	newins "${DISTDIR}"/2.13.12.0.a.5.2.arm 3826.arm
	newins "${DISTDIR}"/2.13.24.0.lm87.arm isl3887usb
	newins "${DISTDIR}"/2.13.1.0.lm86.arm isl3886usb
	newins "${DISTDIR}"/2.13.12.0.arm isl3886pci
}

pkg_preinst() {
	elog "Kernels older than 2.6.29 are not supported by these firmwares."
	elog "If you are running 2.6.28 or older kernels, please emerge:"
	elog "net-wireless/prism54-firmware:0"
	elog "But please note, that firmware is officially deprecated."
}
