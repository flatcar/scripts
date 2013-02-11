# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/ultimate/ultimate-3.0.2.ebuild,v 1.3 2009/09/23 18:45:45 patrick Exp $

inherit eutils fixheadtails

MY_P="Ultimate${PV/_/.}"

DESCRIPTION="An IRCd server based on DALnet's DreamForge IRCd."
SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.bz2"
HOMEPAGE="http://www.shadow-realm.org/"

KEYWORDS="~ppc ~sparc x86"
SLOT="0"
LICENSE="GPL-2"
IUSE="ssl"

DEPEND="ssl? ( dev-libs/openssl )"

S="${WORKDIR}/${MY_P}"

src_unpack() {
	unpack ${A}
	cd ${S}

	epatch ${FILESDIR}/3.0.0_rc2-config.patch

	ht_fix_file configure
}

src_compile() {
	econf \
		--sysconfdir=/etc/ultimateircd \
		--localstatedir=/var/lib/ultimateircd \
		$(use_enable ssl openssl) \
		|| die "econf failed"
	emake || die "Make failed"
}

src_install() {
	dodir /etc/ultimateircd
	keepdir /var/{lib,log,run}/ultimateircd
	fowners nobody /var/{lib,log,run}/ultimateircd

	einstall \
		sysconfdir=${D}/etc/ultimateircd \
		localstatedir=${D}/var/lib/ultimateircd \
		networksubdir=${D}/etc/ultimateircd/networks \
		|| die "einstall failed"

	rm -rf ${D}/usr/{{ircd,kill,rehash},bin/{ircdchk,ssl-{cert,search}.sh}} ${D}/var/lib/ultimateircd/logs
	dosym /var/log/ultimateircd /var/lib/ultimateircd/logs

	mv ${D}/usr/bin/ircd ${D}/usr/bin/ultimateircd
	mv ${D}/usr/bin/mkpasswd ${D}/usr/bin/ultimateircd-mkpasswd

	newinitd ${FILESDIR}/ultimateircd.rc-3.0.0 ultimateircd
	newconfd ${FILESDIR}/ultimateircd.conf ultimateircd
}
