# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/cronie/cronie-1.4.8.ebuild,v 1.6 2012/12/18 22:36:34 polynomial-c Exp $

EAPI="3"

inherit cron eutils pam user

DESCRIPTION="Cronie is a standard UNIX daemon cron based on the original vixie-cron."
SRC_URI="https://fedorahosted.org/releases/c/r/cronie/${P}.tar.gz"
HOMEPAGE="https://fedorahosted.org/cronie/wiki"

LICENSE="ISC BSD BSD-2"
KEYWORDS="amd64 ~arm ~sparc x86"
IUSE="inotify pam"

DEPEND="pam? ( virtual/pam )"
RDEPEND="${DEPEND}"

#cronie supports /etc/crontab
CRON_SYSTEM_CRONTAB="yes"

pkg_setup() {
	enewgroup crontab
}

src_configure() {
	SPOOL_DIR="/var/spool/cron/crontabs" econf \
		$(use_with inotify ) \
		$(use_with pam ) \
		--with-daemon_username=cron \
		--with-daemon_groupname=cron \
		|| die "econf failed"
}

src_install() {
	emake install DESTDIR="${D}" || die "install failed"

	docrondir -m 1730 -o root -g crontab
	fowners root:crontab /usr/bin/crontab
	fperms 2751 /usr/bin/crontab

	insinto /etc
	newins "${FILESDIR}/${PN}-1.2-crontab" crontab
	newins "${FILESDIR}/${PN}-1.2-cron.deny" cron.deny

	keepdir /etc/cron.d
	newinitd "${FILESDIR}/${PN}-1.2-initd" cronie
	newpamd "${FILESDIR}/${PN}-1.4.3-pamd" crond

	dodoc NEWS AUTHORS README
}

pkg_postinst() {
	cron_pkg_postinst
}
