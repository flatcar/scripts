# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/usbutils/usbutils-001.ebuild,v 1.10 2011/08/24 17:35:46 radhermit Exp $

EAPI="2"

DESCRIPTION="USB enumeration utilities"
HOMEPAGE="http://linux-usb.sourceforge.net/"
SRC_URI="mirror://kernel/linux/utils/usb/usbutils/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE="network-cron zlib"

RDEPEND="virtual/libusb:1
	zlib? ( sys-libs/zlib )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_configure() {
	econf \
		--datarootdir=/usr/share \
		--datadir=/usr/share/misc \
		$(use_enable zlib)
}

src_install() {
	emake DESTDIR="${D}" install || die
	mv "${D}"/usr/sbin/update-usbids{.sh,} || die
	newbin "${FILESDIR}"/usbmodules.sh usbmodules || die
	dodoc AUTHORS ChangeLog NEWS README

	use network-cron || return 0
	exeinto /etc/cron.monthly
	newexe "${FILESDIR}"/usbutils.cron update-usbids || die
}
