# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libcgroup/libcgroup-0.38-r1.ebuild,v 1.4 2013/01/05 11:24:38 pinkbyte Exp $

EAPI="4"

inherit autotools eutils linux-info pam

DESCRIPTION="Tools and libraries to configure and manage kernel control groups"
HOMEPAGE="http://libcg.sourceforge.net/"
SRC_URI="mirror://sourceforge/libcg/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE="+daemon debug pam static-libs +tools"

RDEPEND="pam? ( virtual/pam )"

DEPEND="${RDEPEND}
	sys-devel/bison
	sys-devel/flex"

pkg_setup() {
	if use daemon && ! use tools; then
		eerror "The daemon USE flag requires tools USE flag."
		die "Please enable tools or disable daemon."
	fi

	local CONFIG_CHECK="~CGROUPS"
	if use daemon; then
		CONFIG_CHECK="${CONFIG_CHECK} ~CONNECTOR ~PROC_EVENTS"
	fi
	linux-info_pkg_setup
}

src_prepare() {
	# Change rules file location
	sed -e 's:/etc/cgrules.conf:/etc/cgroup/cgrules.conf:' \
		-i src/libcgroup-internal.h || die "sed failed"
	sed -e 's:\(pam_cgroup_la_LDFLAGS.*\):\1\ -avoid-version:' \
		-i src/pam/Makefile.am || die "sed failed"

	eautoreconf
}

src_configure() {
	my_conf="--enable-shared
		--libdir=/usr/$(get_libdir)
		$(use_enable daemon)
		$(use_enable debug)
		$(use_enable pam)
		$(use_enable static-libs static)
		$(use_enable tools)"

	if use pam; then
		my_conf="${my_conf} --enable-pam-module-dir=$(getpam_mod_dir)"
	fi

	# bug #450302
	econf ${my_conf} --disable-silent-rules
}

src_install() {
	emake DESTDIR="${D}" install || die "Install failed"
	find "${D}" -name "*.la" -delete || die "la removal failed"

	insinto /etc/cgroup
	doins samples/cgrules.conf || die

	if use tools; then
		doins samples/cgconfig.conf || die

		newconfd "${FILESDIR}"/cgconfig.confd cgconfig || die
		newinitd "${FILESDIR}"/cgconfig.initd cgconfig || die
	fi

	if use daemon; then
		newconfd "${FILESDIR}"/cgred.confd cgred || die
		newinitd "${FILESDIR}"/cgred.initd cgred || die
	fi
}

pkg_postinst() {
	elog "Read the kernel docs on cgroups, related schedulers, and the"
	elog "block I/O controllers.  The Redhat Resource Management Guide"
	elog "is also helpful.  DO NOT enable the cgroup namespace subsytem"
	elog "if you want a custom config, rule processing, etc.  This option"
	elog "should only be enabled for a VM environment.  The UID wildcard"
	elog "rules seem to work only without a custom config (since wildcards"
	elog "don't work in config blocks).  Specific user-id configs *do*"
	elog "work, but be careful about how the mem limits add up if using"
	elog "the memory.limit_* directives.  There should be a basic task"
	elog "partitioning into the default group when running cgred with no"
	elog "specific config blocks or rules (other than the mount directive)."
	elog "See the docs for the pam module config, and as always, RTFM..."
}
