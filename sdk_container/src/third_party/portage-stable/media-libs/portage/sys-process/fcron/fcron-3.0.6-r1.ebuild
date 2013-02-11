# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/fcron/fcron-3.0.6-r1.ebuild,v 1.11 2013/01/20 13:10:30 ago Exp $

inherit cron pam eutils flag-o-matic user

MY_P=${P/_/-}
DESCRIPTION="A command scheduler with extended capabilities over cron and anacron"
HOMEPAGE="http://fcron.free.fr/"
SRC_URI="http://fcron.free.fr/archives/${MY_P}.src.tar.gz"

LICENSE="GPL-2"
KEYWORDS="amd64 arm hppa ia64 ~mips ppc sparc x86 ~x86-fbsd"
IUSE="debug pam selinux linguas_fr"

DEPEND="selinux? ( sys-libs/libselinux )
	pam? ( virtual/pam )"

# see bug 282214 for the reason to depend on bash
RDEPEND="${DEPEND}
	app-shells/bash
	>=app-misc/editor-wrapper-3
	pam? ( >=sys-auth/pambase-20100310 )"

S="${WORKDIR}/${MY_P}"

pkg_setup() {
	enewgroup fcron
	enewuser fcron -1 -1 -1 fcron
	rootuser=$(egetent passwd 0 | cut -d ':' -f 1)
	rootgroup=$(egetent group 0 | cut -d ':' -f 1)
}

src_unpack() {
	unpack ${A}
	cd "${S}"

	# respect LDFLAGS
	sed -i "s:\(@LIBS@\):\$(LDFLAGS) \1:" Makefile.in || die "sed failed"

	sed -i -e 's:/etc/fcrontab:/etc/fcron/fcrontab:' script/check_system_crontabs.sh || die
}

src_compile() {
	local myconf

	# Don't try to pass --with-debug as it'll play with cflags as
	# well, and run foreground which is a _very_ nasty idea for
	# Gentoo.
	use debug && append-flags -DDEBUG

	[[ -n "${rootuser}" ]] && myconf="${myconf} --with-rootname=${rootuser}"
	[[ -n "${rootgroup}" ]] && myconf="${myconf} --with-rootgroup=${rootgroup}"

	econf \
		--with-cflags="${CFLAGS}" \
		$(use_with pam) \
		$(use_with selinux) \
		--sysconfdir=/etc/fcron \
		--with-username=fcron \
		--with-groupname=fcron \
		--with-piddir=/var/run \
		--with-spooldir=/var/spool/fcron \
		--with-fifodir=/var/run \
		--with-fcrondyn=yes \
		--disable-checks \
		--with-editor=/usr/libexec/editor \
		--with-sendmail=/usr/sbin/sendmail \
		--with-shell=/bin/sh \
		--without-db2man --without-dsssl-dir \
		${myconf} \
		|| die "configure failed"

	emake || die "make failed"

	# bug #216460
	sed -i \
		-e 's:/usr/local/etc/fcron:/etc/fcron/fcron:g' \
		-e 's:/usr/local/etc:/etc:g' \
		-e 's:/usr/local/:/usr/:g' \
		doc/*/*/*.{txt,1,5,8,html} \
		|| die "unable to fix documentation references"
}

src_install() {
	# create directories that don't have special permissions first so
	# that we can play with the permissions later
	dodir /usr/bin /etc /var/spool

	diropts -m6770 -o fcron -g fcron
	keepdir /var/spool/fcron

	# install fcron tools
	insinto /usr/bin
	dosbin fcron || die

	# fcronsighup needs to be suid root, because it sends a HUP
	# to the running fcron daemon
	insopts -m6755 -o ${rootuser:-root} -g fcron
	doins fcronsighup || die
	insopts -m6755 -o fcron -g fcron
	doins fcrondyn fcrontab || die

	# /etc stuff
	diropts -m0750 -o ${rootuser:-root} -g fcron
	dodir /etc/fcron
	insinto /etc/fcron
	insopts -m0640 -o ${rootuser:-root} -g fcron
	doins files/fcron.{allow,deny,conf} || die

	diropts -m0755
	insopts -m0644

	# install /etc/crontab and /etc/fcrontab
	insopts -m0640 -o ${rootuser:-root} -g ${rootgroup:-root}
	doins "${FILESDIR}"/fcrontab || die

	# install PAM files
	pamd_mimic system-services fcron auth account session
	cat - > "${T}"/fcrontab.pam <<EOF
# Don't ask for the user's password; fcrontab will only allow to
# change user if running as root.
auth		sufficient		pam_permit.so

# Still use the system-auth stack for account and session as the
# sysadmin might have set up stuff properly, and also avoids
# sidestepping limits (since fcrontab will run $EDITOR).
account		include			system-auth
session		include			system-auth
EOF
	newpamd "${T}"/fcrontab.pam fcrontab

	# install init script
	newinitd "${FILESDIR}"/fcron.init.2 fcron || die

	# install the very handy check_system_crontabs script, POSIX sh variant
	newsbin script/check_system_crontabs.sh check_system_crontabs || die

	# doc stuff
	dodoc MANIFEST VERSION "${FILESDIR}"/crontab \
		doc/en/txt/{readme,thanks,faq,todo,relnotes,changes}.txt \
		|| die
	newdoc files/fcron.conf fcron.conf.sample || die
	dohtml doc/en/HTML/*.html || die
	doman doc/en/man/*.{1,5,8} || die

	# localized docs
	for lang in fr; do
		use linguas_${lang} || continue

		doman -i18n=${lang} doc/${lang}/man/*.{1,5,8} || die
		docinto html/${lang}
		dohtml doc/${lang}/HTML/*.html || die
	done
}

pkg_postinst() {
	elog
	elog "fcron has some important differences compared to vixie-cron:"
	elog
	elog "1. fcron stores the crontabs in ${ROOT}var/spool/fcron"
	elog "   instead of ${ROOT}var/spool/cron/crontabs"
	elog
	elog "2. fcron uses a special binary file format for storing the"
	elog "   crontabs in ${ROOT}var/spool/fcron/USERNAME,"
	elog "   but the original plain text version is saved as"
	elog "   ${ROOT}var/spool/fcron/USERNAME.orig for your"
	elog "   reference (and for being edited with fcrontab)."
	elog
	elog "3. fcron does not feature a system crontab in exactly the"
	elog "   same way as vixie-cron does. This version of fcron"
	elog "   features a crontab for a pseudo-user 'systab' for use"
	elog "   as the system crontab. Running a command like"
	elog
	elog "      fcrontab -u systab ${ROOT}etc/crontab"
	elog
	elog "   will write ${ROOT}etc/crontab to the fcron crontabs directory as"
	elog
	elog "      ${ROOT}var/spool/fcron/systab"
	elog
	elog "   Please note that changes to ${ROOT}etc/crontab will not become"
	elog "   active automatically! fcron also does not use the directory"
	elog "   ${ROOT}etc/cron.d by default like vixie-cron does."
	elog "   Fortunately, it's possible to emulate vixie-cron's behavior"
	elog "   with regards to ${ROOT}etc/crontab and ${ROOT}etc/cron.d by using a"
	elog "   little helper script called 'check_system_crontabs'."
	elog "   The file ${ROOT}etc/fcron/fcrontab (not ${ROOT}etc/crontab!) has been set up"
	elog "   to run the script once a while to check whether"
	elog "   ${ROOT}etc/fcron/fcrontab, ${ROOT}etc/crontab or files in ${ROOT}etc/cron.d/ have"
	elog "   changed since the last generation of the systab and"
	elog "   regenerate it from those three locations as necessary."
	elog "   You should now run 'check_system_crontabs' once to properly"
	elog "   generate an initial systab:"
	elog
	elog "      check_system_crontabs -v -i -f"
	elog
	elog "   The file ${ROOT}etc/fcron/fcrontab should only be used to run that"
	elog "   script in order to ensure independence from the standard"
	elog "   system crontab file ${ROOT}etc/crontab."
	elog "   You may of course adjust the schedule for the script"
	elog "   'check_system_crontabs' or any other setting in"
	elog "   ${ROOT}etc/fcron/fcrontab as you desire."
	elog
	elog "If you do NOT want to use 'check_system_crontabs', you"
	elog "might still want to activate the use of the well known"
	elog "directories ${ROOT}etc/cron.{hourly|daily|weekly|monthly} by"
	elog "just generating a systab once from ${ROOT}etc/crontab:"
	elog
	elog "   fcrontab -u systab ${ROOT}etc/crontab"
	elog
	elog "Happy fcron'ing!"
	elog

	ewarn
	ewarn "Fixing permissions and ownership of ${ROOT}usr/bin/fcron{tab,dyn,sighup}"
	chown fcron:fcron "${ROOT}"usr/bin/fcron{tab,dyn} >&/dev/null
	chown ${rootuser:-root}:fcron "${ROOT}"usr/bin/fcronsighup >&/dev/null
	chmod 6755 "${ROOT}"usr/bin/fcron{tab,dyn,sighup} >&/dev/null
	ewarn "Fixing permissions and ownership of ${ROOT}etc/{fcron,crontab}"
	chown -R ${rootuser:-root}:fcron "${ROOT}"etc/{fcron,crontab} >&/dev/null
	chmod -R g+rX,o= "${ROOT}"etc/fcron "${ROOT}"etc/{fcron,crontab} >&/dev/null
	ewarn

	ewarn
	ewarn "WARNING: fcron now uses a dedicated user and group"
	ewarn "'fcron' for the suid/sgid programs/files instead of"
	ewarn "the user and group 'cron' that were previously used."
	ewarn
	ewarn "fcron usage can now only be restricted by adding users"
	ewarn "to the following files instead of to the group 'cron':"
	ewarn
	ewarn "   ${ROOT}etc/fcron/fcron.allow"
	ewarn "   ${ROOT}etc/fcron/fcron.deny"
	ewarn

	if ls -1 "${ROOT}"var/spool/cron/fcrontabs/* >&/dev/null; then
		ewarn
		ewarn "WARNING: fcron now uses a dedicated fcron-specific"
		ewarn "spooldir ${ROOT}var/spool/fcron instead of the commonly"
		ewarn "used ${ROOT}var/spool/cron for several reasons."
		ewarn
		ewarn "Copying over existing crontabs from ${ROOT}var/spool/cron/fcrontabs"
		cp "${ROOT}"var/spool/cron/fcrontabs/* "${ROOT}"var/spool/fcron/ >&/dev/null \
			|| die "failed to migrate existing crontabs"
		ewarn "You should now remove ${ROOT}var/spool/cron/fcrontabs!"
		ewarn
		ewarn "Fixing permissions and ownership of ${ROOT}var/spool/fcron"
		chown root:root "${ROOT}"var/spool/fcron/* >&/dev/null
		chmod 0600 "${ROOT}"var/spool/fcron/* >&/dev/null
		chown fcron:fcron "${ROOT}"var/spool/fcron/*.orig >&/dev/null
		chmod 0640 "${ROOT}"var/spool/fcron/*.orig >&/dev/null
		ewarn
		ewarn "*** YOU SHOULD IMMEDIATELY UPDATE THE"
		ewarn "*** fcrontabs ENTRY IN ${ROOT}etc/fcron/fcron.conf"
		ewarn "*** AND RESTART YOUR FCRON DAEMON!"
	fi

	elog ""
	elog "Since version 3.0.5 the fcron init script will no longer wait for LDAP, MySQL"
	elog "or PostgreSQL before starting. If you need any of these for authentication or"
	elog "for jobs that are executed by fcron, please create a /etc/conf.d/fcron file to"
	elog "set the rc_need variable to the list of services you should be waiting for."
	elog ""
}
