# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/wifi-radar/wifi-radar-2.0.8-r1.ebuild,v 1.5 2012/12/16 13:52:50 ago Exp $

EAPI=4

PYTHON_DEPEND="2:2.6"

inherit eutils versionator python

MY_PV="$(get_version_component_range 1-2)"
MY_PL="$(get_version_component_range 3)"
MY_PL="s0${MY_PL}"
MY_PV="${MY_PV}.${MY_PL}"

DESCRIPTION="WiFi Radar is a Python/PyGTK2 utility for managing WiFi profiles."
HOMEPAGE="http://wifi-radar.berlios.de/"
SRC_URI="mirror://berlios/${PN}/${PN}-${MY_PV}.tar.bz2"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE=""

RDEPEND=">=dev-python/pygtk-2.16.0-r1
	>=net-wireless/wireless-tools-29
	|| ( net-misc/dhcpcd net-misc/dhcp net-misc/pump )"

S="${WORKDIR}/${PN}-${MY_PV}"

src_prepare() {
	sed -i "s:/etc/wpa_supplicant.conf:/etc/wpa_supplicant/wpa_supplicant.conf:" ${PN} || die
}

src_install() {
	python_convert_shebangs -r 2 .
	dosbin ${PN}
	dobin ${PN}.sh
	doicon -s scalable pixmaps/${PN}.svg
	doicon -s 32 pixmaps/wifi_radar_32x32.png
	doicon pixmaps/${PN}.png
	make_desktop_entry ${PN}.sh "WiFi Radar" ${PN} Network

	doman man/man1/${PN}.1 man/man5/${PN}.conf.5

	cd docs
	dodoc BUGS CREDITS DEVELOPER_GUIDELINES HISTORY README README.WPA-Mini-HOWTO.txt TODO
	keepdir /etc/${PN}
}

pkg_postinst() {
	einfo "Remember to edit configuration file /etc/${PN}.conf to suit your needs..."
	echo
	einfo "To use ${PN} with a normal user (with sudo) add:"
	einfo "%users   ALL = /usr/sbin/${PN}"
	einfo "in your /etc/sudoers. Also, find the line saying:"
	einfo "Defaults      env_reset"
	einfo "and modify it as follows:"
	einfo "Defaults      env_keep=DISPLAY"
	echo
	einfo "Then launch ${PN}.sh"
	echo
}
