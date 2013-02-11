# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/procps/procps-3.2.8_p10-r1.ebuild,v 1.2 2011/09/06 18:44:05 mattst88 Exp $

EAPI="2"

inherit flag-o-matic eutils toolchain-funcs multilib

DEB_VER=${PV#*_p}
MY_PV=${PV%_p*}
MY_P="${PN}-${MY_PV}"
DESCRIPTION="Standard informational utilities and process-handling tools"
HOMEPAGE="http://procps.sourceforge.net/"
SRC_URI="http://procps.sourceforge.net/${MY_P}.tar.gz
	mirror://debian/pool/main/p/procps/${PN}_${MY_PV}-${DEB_VER}.debian.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="unicode"

RDEPEND=">=sys-libs/ncurses-5.2-r2[unicode?]"

S=${WORKDIR}/${MY_P}

src_prepare() {
	local p d="${WORKDIR}"/debian/patches
	pushd "${d}" >/dev/null
	# makefile_dev_null: this bug is actually in gcc and is already fixed
	for p in $(use unicode || echo watch_{unicode,ansi_colour}) makefile_dev_null ; do
		rm ${p}.patch || die
		sed -i "/^${p}/d" series || die
	done
	popd >/dev/null
	EPATCH_SOURCE="${d}" \
	epatch $(<"${d}"/series)
	# fixup debian watch_exec_beep.patch
	sed -i '1i#include <sys/wait.h>' watch.c || die

	epatch "${FILESDIR}"/${PN}-3.2.7-proc-mount.patch
	epatch "${FILESDIR}"/${PN}-3.2.3-noproc.patch
	epatch "${FILESDIR}"/${PN}-3.2.8-toprc-fixup.patch
	epatch "${FILESDIR}"/${PN}-3.2.8-r1-forest-prefix.patch

	# Clean up the makefile
	#  - we do stripping ourselves
	#  - punt fugly gcc flags
	sed -i \
		-e '/install/s: --strip : :' \
		-e '/ALL_CFLAGS += $(call check_gcc,-fweb,)/d' \
		-e '/ALL_CFLAGS += $(call check_gcc,-Wstrict-aliasing=2,)/s,=2,,' \
		-e "/^lib64/s:=.*:=$(get_libdir):" \
		-e 's:-m64::g' \
		Makefile || die "sed Makefile"

	# mips 2.4.23 headers (and 2.6.x) don't allow PAGE_SIZE to be defined in
	# userspace anymore, so this patch instructs procps to get the
	# value from sysconf().
	epatch "${FILESDIR}"/${PN}-mips-define-pagesize.patch

	# lame unicode stuff checks glibc defines
	sed -i "s:__GNU_LIBRARY__ >= 6:0 == $(use unicode; echo $?):" proc/escape.c || die
}

src_compile() {
	replace-flags -O3 -O2
	emake \
		CC="$(tc-getCC)" \
		CPPFLAGS="${CPPFLAGS}" \
		CFLAGS="${CFLAGS}" \
		LDFLAGS="${LDFLAGS}" \
		|| die "make failed"
}

src_install() {
	emake \
		ln_f="ln -sf" \
		ldconfig="true" \
		DESTDIR="${D}" \
		install \
		|| die "install failed"

	insinto /usr/include/proc
	doins proc/*.h || die

	dodoc sysctl.conf BUGS NEWS TODO ps/HACKING

	# compat symlink so people who shouldnt be using libproc can #170077
	dosym libproc-${MY_PV}.so /$(get_libdir)/libproc.so || die
}
