# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/cronie/cronie-1.4.9-r5.ebuild,v 1.1 2013/01/23 17:25:24 polynomial-c Exp $

EAPI="5"

inherit cron eutils pam systemd user

DESCRIPTION="Cronie is a standard UNIX daemon cron based on the original vixie-cron."
SRC_URI="https://fedorahosted.org/releases/c/r/cronie/${P}.tar.gz"
HOMEPAGE="https://fedorahosted.org/cronie/wiki"

LICENSE="ISC BSD BSD-2"
KEYWORDS="~amd64 ~arm ~sparc ~x86"
IUSE="anacron inotify pam selinux"

DEPEND="pam? ( virtual/pam )
	anacron? ( !sys-process/anacron )"
RDEPEND="${DEPEND}"

#cronie supports /etc/crontab
CRON_SYSTEM_CRONTAB="yes"

pkg_setup() {
	enewgroup crontab
}

src_configure() {
	SPOOL_DIR="/var/spool/cron/crontabs" \
	ANACRON_SPOOL_DIR="/var/spool/anacron" \
	econf \
		$(use_with inotify) \
		$(use_with pam) \
		$(use_with selinux) \
		$(use_enable anacron) \
		--with-syscrontab \
		--with-daemon_username=cron \
		--with-daemon_groupname=cron
}

src_install() {
	emake install DESTDIR="${D}"

	docrondir -m 1730 -o root -g crontab
	fowners root:crontab /usr/bin/crontab
	fperms 2751 /usr/bin/crontab

	insinto /etc/conf.d
	newins "${S}"/crond.sysconfig ${PN}

	insinto /etc
	newins "${FILESDIR}/${PN}-1.2-crontab" crontab
	newins "${FILESDIR}/${PN}-1.2-cron.deny" cron.deny

	keepdir /etc/cron.d
	newinitd "${FILESDIR}/${PN}-1.3-initd" ${PN}
	newpamd "${FILESDIR}/${PN}-1.4.3-pamd" crond

	sed s:sysconfig/crond:conf.d/cronie: contrib/cronie.systemd > "${T}"/cronie.service
	systemd_dounit "${T}"/cronie.service

	if use anacron ; then
		keepdir /var/spool/anacron
		fowners root:cron /var/spool/anacron
		fperms 0750 /var/spool/anacron

		insinto /etc

		newinitd "${FILESDIR}"/anacron-1.0-initd anacron

		# Install this without execute permission.
		# User can enable it with chmod +x.
		insinto /etc/cron.hourly
		doins contrib/0anacron
	fi

	dodoc AUTHORS README contrib/*
}

pkg_postinst() {
	cron_pkg_postinst
}
