# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/bluez-hcidump/bluez-hcidump-2.0.ebuild,v 1.5 2011/10/26 11:37:48 xarthisius Exp $

EAPI=4
inherit eutils

DESCRIPTION="Bluetooth HCI packet analyzer"
HOMEPAGE="http://bluez.sourceforge.net/"
SRC_URI="mirror://kernel/linux/bluetooth/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 hppa ppc x86"
IUSE=""

RDEPEND=">=net-wireless/bluez-4.90"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

DOCS=( AUTHORS ChangeLog README )

src_prepare() {
	epatch "${FILESDIR}"/${P}-bluez-4.9x.patch
}
