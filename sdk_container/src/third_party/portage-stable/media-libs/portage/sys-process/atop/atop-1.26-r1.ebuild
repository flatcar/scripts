# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/atop/atop-1.26-r1.ebuild,v 1.1 2012/01/09 21:45:56 sping Exp $

EAPI="3"

inherit eutils toolchain-funcs

DESCRIPTION="Resource-specific view of processes"
HOMEPAGE="http://www.atoptool.nl/"
SRC_URI="http://www.atoptool.nl/download/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~hppa ~ppc ~x86"
IUSE=""

DEPEND="sys-process/acct"

src_prepare() {
	sed -i \
		-e '/^CFLAGS/s: = -O : += :' \
		-e '/^LDFLAGS/s: = : += :' \
		-e 's:\<cc\>:$(CC):' \
		Makefile
	tc-export CC
	cp "${FILESDIR}"/atop.rc atop.init
	chmod a+rx atop.init
	sed -i 's: root : :' atop.cron #191926

	epatch "${FILESDIR}"/${P}-cve-2011-3618.patch  # bug 363887
}

src_install() {
	emake DESTDIR="${D}" INIPATH=/etc/init.d install || die
	# useless -${PV} copies ?
	rm -f "${D}"/usr/bin/atop*-${PV}
	dodoc README "${D}"/etc/cron.d/*
	rm -r "${D}"/etc/cron.d || die
}
