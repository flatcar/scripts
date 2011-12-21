# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/valgrind/valgrind-3.6.1-r1.ebuild,v 1.4 2011/12/21 15:47:15 josejx Exp $

EAPI=2
inherit autotools eutils flag-o-matic toolchain-funcs multilib pax-utils

DESCRIPTION="An open-source memory debugger for GNU/Linux"
HOMEPAGE="http://www.valgrind.org"
SRC_URI="http://www.valgrind.org/downloads/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* amd64 ppc ppc64 x86 ~amd64-linux ~x86-linux"
IUSE="mpi qt4"

DEPEND="mpi? ( virtual/mpi )"
RDEPEND="${DEPEND}"

src_prepare() {
	# Respect CFLAGS, LDFLAGS
	sed -i -e '/^CPPFLAGS =/d' -e '/^CFLAGS =/d' -e '/^LDFLAGS =/d' \
		mpi/Makefile.am || die

	# Changing Makefile.all.am to disable SSP
	sed -i -e 's:^AM_CFLAGS_BASE = :AM_CFLAGS_BASE = -fno-stack-protector :' \
		Makefile.all.am || die

	# Correct hard coded doc location
	sed -i -e "s:doc/valgrind:doc/${PF}:" \
		docs/Makefile.am || die

	# Yet more local labels, this time for ppc32 & ppc64
	epatch "${FILESDIR}"/${PN}-3.6.0-local-labels.patch

	# Don't build in empty assembly files for other platforms or we'll get a QA
	# warning about executable stacks.
	epatch "${FILESDIR}"/${PN}-3.6.0-non-exec-stack.patch

	# Fix up some suppressions that were not general enough for glibc versions
	# with more than just a major and minor number.
	epatch "${FILESDIR}"/${PN}-3.4.1-glibc-2.10.1.patch

	# Remove automagic dependency on qt4
	epatch "${FILESDIR}"/${PN}-3.6.1-user-enable-qt4.patch

	# Allow valgrind to build against linux-3, bug #370857
	epatch "${FILESDIR}"/${PN}-3.6.1-linux-3.patch

	# Regenerate autotools files
	eautoreconf
}

src_configure() {
	local myconf

	# -fomit-frame-pointer	"Assembler messages: Error: junk `8' after expression"
	#                       while compiling insn_sse.c in none/tests/x86
	# -fpie                 valgrind seemingly hangs when built with pie on
	#                       amd64 (bug #102157)
	# -fstack-protector     more undefined references to __guard and __stack_smash_handler
	#                       because valgrind doesn't link to glibc (bug #114347)
	# -ggdb3                segmentation fault on startup
	filter-flags -fomit-frame-pointer
	filter-flags -fpie
	filter-flags -fstack-protector
	replace-flags -ggdb3 -ggdb2

	if use amd64 || use ppc64; then
		! has_multilib_profile && myconf="${myconf} --enable-only64bit"
	fi

	# Don't use mpicc unless the user asked for it (bug #258832)
	if ! use mpi; then
		myconf="${myconf} --without-mpicc"
	fi

	if ! use qt4; then
		myconf="${myconf} --disable-qtcore"
	fi

	econf ${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS FAQ.txt NEWS README*

	pax-mark m "${D}"/usr/$(get_libdir)/valgrind/*-*-linux
}

pkg_postinst() {
	if use ppc || use ppc64 || use amd64 ; then
		ewarn "Valgrind will not work on ppc, ppc64 or amd64 if glibc does not have"
		ewarn "debug symbols (see https://bugs.gentoo.org/show_bug.cgi?id=214065"
		ewarn "and http://bugs.gentoo.org/show_bug.cgi?id=274771)."
		ewarn "To fix this you can add splitdebug to FEATURES in make.conf and"
		ewarn "remerge glibc."
	fi
}
