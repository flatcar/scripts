# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/wireless-regdb/wireless-regdb-20110428-r1.ebuild,v 1.11 2013/01/06 10:06:54 ago Exp $

inherit multilib

MY_P="wireless-regdb-${PV:0:4}.${PV:4:2}.${PV:6:2}"
DESCRIPTION="Binary regulatory database for CRDA"
HOMEPAGE="http://wireless.kernel.org/en/developers/Regulatory"
SRC_URI="http://wireless.kernel.org/download/wireless-regdb/${MY_P}.tar.bz2"
LICENSE="ISC"
SLOT="0"

KEYWORDS="~alpha amd64 arm ~ia64 ~mips ppc ppc64 ~sparc x86"
IUSE=""

S="${WORKDIR}/${MY_P}"

src_compile() {
	einfo "Recompiling regulatory.bin from db.txt would break CRDA verify. Installing untouched binary version."
}

src_install() {
	insinto /usr/$(get_libdir)/crda/
	doins regulatory.bin

	insinto /etc/wireless-regdb/pubkeys
	doins linville.key.pub.pem

	doman regulatory.bin.5
	dodoc README db.txt
}
