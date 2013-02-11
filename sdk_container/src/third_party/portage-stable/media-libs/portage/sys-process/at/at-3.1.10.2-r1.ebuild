# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/at/at-3.1.10.2-r1.ebuild,v 1.11 2012/03/13 15:07:05 polynomial-c Exp $

inherit eutils flag-o-matic autotools pam

DESCRIPTION="Queues jobs for later execution"
HOMEPAGE="http://packages.qa.debian.org/a/at.html"
SRC_URI="mirror://debian/pool/main/a/at/at_${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 ~arm hppa ia64 ppc ppc64 sparc x86"
IUSE="pam"

DEPEND="virtual/mta
	sys-devel/bison
	>=sys-devel/flex-2.5.4a
	pam? ( virtual/pam )"
RDEPEND="virtual/mta
	virtual/logger"

pkg_setup() {
	enewgroup at 25
	enewuser at 25 -1 /var/spool/at/atjobs at
}

src_unpack() {
	unpack ${A}
	cd "${S}"

	epatch "${FILESDIR}"/${PN}-3.1.8-more-deny.patch
	epatch "${FILESDIR}"/${PN}-3.1.10.1-Makefile.patch
	# fix parallel make issues, bug #244884
	epatch "${FILESDIR}"/${P}-Makefile.in-parallel-make-fix.patch
	epatch "${FILESDIR}"/${P}-configure.in-fix-PAM-automagick-dep.patch

	# fixing version string shown on "at -V" - bug #252970
	sed -e "/^VERSION=/s:3\.1\.9:${PV}:" -i "${S}"/configure.in \
		|| die "sed configure.in failed"
	eautoconf
}

src_compile() {
	use pam || my_conf="--without-pam"
	econf \
		--sysconfdir=/etc/at \
		--with-jobdir=/var/spool/at/atjobs \
		--with-atspool=/var/spool/at/atspool \
		--with-etcdir=/etc/at \
		--with-daemon_username=at \
		--with-daemon_groupname=at \
		${my_conf} \
		|| die "configure failed"

	emake || die "make failed"
}

src_install() {
	make install IROOT="${D}" || die

	newinitd "${FILESDIR}"/atd.rc6 atd
	newpamd "${FILESDIR}"/at.pamd atd
	prepalldocs

	# Preserve existing .SEQ files (bug #386625)
	local seq_file="${ROOT}/var/spool/at/atjobs/.SEQ"
	if [ -f "${seq_file}" ] ; then
		einfo"Preserving existing .SEQ file (bug #386625)."
		cp -p "${seq_file}" "${D}"/var/spool/at/atjobs/ || die
	fi
}

pkg_postinst() {
	einfo "Forcing correct permissions on /var/spool/at"
	chown at:at "${ROOT}/var/spool/at/atjobs"
	chmod 1770  "${ROOT}/var/spool/at/atjobs"
	chown at:at "${ROOT}/var/spool/at/atjobs/.SEQ"
	chmod 0600  "${ROOT}/var/spool/at/atjobs/.SEQ"
	chown at:at "${ROOT}/var/spool/at/atspool"
	chmod 1770  "${ROOT}/var/spool/at/atspool"
}
