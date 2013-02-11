# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/broadcom-sta/broadcom-sta-5.100.82.112-r2.ebuild,v 1.4 2012/05/22 02:55:18 zmedico Exp $

EAPI="4"
inherit eutils linux-mod

DESCRIPTION="Broadcom's IEEE 802.11a/b/g/n hybrid Linux device driver."
HOMEPAGE="http://www.broadcom.com/support/802.11/linux_sta.php"
SRC_BASE="http://www.broadcom.com/docs/linux_sta/hybrid-portsrc_x86_"
SRC_URI="x86? ( ${SRC_BASE}32-v${PV//\./_}.tar.gz )
	amd64? ( ${SRC_BASE}64-v${PV//\./_}.tar.gz )"

LICENSE="Broadcom"
KEYWORDS="amd64 x86"
IUSE=""

RESTRICT="mirror"

DEPEND="virtual/linux-sources"
RDEPEND=""

S="${WORKDIR}"

MODULE_NAMES="wl(net/wireless)"
MODULESD_WL_ALIASES=("wlan0 wl")

pkg_setup() {
	# bug #300570
	# NOTE<lxnay>: module builds correctly anyway with b43 and SSB enabled
	# make checks non-fatal. The correct fix is blackisting ssb and, perhaps
	# b43 via udev rules. Moreover, previous fix broke binpkgs support.
	CONFIG_CHECK="~!B43 ~!SSB"
	if kernel_is ge 2 6 32; then
		CONFIG_CHECK="${CONFIG_CHECK} CFG80211 LIB80211 ~!MAC80211"
	elif kernel_is ge 2 6 31; then
		CONFIG_CHECK="${CONFIG_CHECK} LIB80211 WIRELESS_EXT ~!MAC80211"
	elif kernel_is ge 2 6 29; then
		CONFIG_CHECK="${CONFIG_CHECK} LIB80211 WIRELESS_EXT ~!MAC80211 COMPAT_NET_DEV_OPS"
	else
		CONFIG_CHECK="${CONFIG_CHECK} IEEE80211 IEEE80211_CRYPT_TKIP"
	fi
	linux-mod_pkg_setup

	BUILD_PARAMS="-C ${KV_DIR} M=${S}"
	BUILD_TARGETS="wl.ko"
}

src_prepare() {
	epatch "${FILESDIR}/${PN}-5.10.91.9-license.patch" \
		"${FILESDIR}/${PN}-5.100.82.38-gcc.patch" \
		"${FILESDIR}/${PN}-5.100.82.111-linux-3.0.patch" \
		"${FILESDIR}/${PN}-5.100.82.112-linux-2.6.39.patch" \
		"${FILESDIR}/${PN}-5.100.82.112-linux-3.2.patch"
	sed -e "s:^#include <asm/system.h>$:#if LINUX_VERSION_CODE < KERNEL_VERSION(3, 4, 0)\\n\\0\\n#endif:" \
		-i src/wl/sys/wl_linux.c || die "sed failed to patch for linux-3.4"
}
