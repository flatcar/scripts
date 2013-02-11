# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/rtl-sdr/rtl-sdr-9999.ebuild,v 1.2 2012/08/11 09:09:08 chithanh Exp $

EAPI=4
inherit autotools base git-2

DESCRIPTION="turns your Realtek RTL2832 based DVB dongle into a SDR receiver"
HOMEPAGE="http://sdr.osmocom.org/trac/wiki/rtl-sdr"
SRC_URI=""
EGIT_REPO_URI="git://git.osmocom.org/${PN}.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE=""

RDEPEND="virtual/libusb:1"
DEPEND="${RDEPEND}"

DOCS=( ${PN}.rules )

src_prepare() {
	eautoreconf
}

pkg_postinst() {
	local rulesfiles=( "${EPREFIX}"/etc/udev/rules.d/*${PN}.rules )
	if [[ ! -f ${rulesfiles} ]]; then
		elog "In order to allow users outside the usb group to capture samples, install"
		elog "${PN}.rules from the documentation directory to ${EPREFIX}/etc/udev/rules.d/"
	fi
}
