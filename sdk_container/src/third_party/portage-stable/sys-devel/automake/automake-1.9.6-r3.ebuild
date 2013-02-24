# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/automake/automake-1.9.6-r3.ebuild,v 1.9 2012/04/26 13:42:44 aballier Exp $

inherit eutils

DESCRIPTION="Used to generate Makefile.in from Makefile.am"
HOMEPAGE="http://www.gnu.org/software/automake/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="${PV:0:3}"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd"
IUSE=""

RDEPEND="dev-lang/perl
	sys-devel/automake-wrapper
	>=sys-devel/autoconf-2.59-r6
	>=sys-apps/texinfo-4.7
	sys-devel/gnuconfig"
DEPEND="${RDEPEND}
	sys-apps/help2man"

src_unpack() {
	unpack ${A}
	cd "${S}"
	sed -i \
		-e "/^@setfilename/s|automake|automake${SLOT}|" \
		-e "s|automake: (automake)|automake v${SLOT}: (automake${SLOT})|" \
		-e "s|aclocal: (automake)|aclocal v${SLOT}: (automake${SLOT})|" \
		doc/automake.texi || die "sed failed"
	epatch "${FILESDIR}"/${PN}-1.9.6-infopage-namechange.patch
	epatch "${FILESDIR}"/${P}-include-dir-prefix.patch #107435
	epatch "${FILESDIR}"/${P}-ignore-comments.patch #126388
	epatch "${FILESDIR}"/${P}-aclocal7-test-sleep.patch #197366
	epatch "${FILESDIR}"/${PN}-1.9.6-subst-test.patch #222225
	epatch "${FILESDIR}"/${PN}-1.10-ccnoco-ldflags.patch #203914
	epatch "${FILESDIR}"/${PN}-1.8.5-CVE-2009-4029.patch #295357
	export WANT_AUTOCONF=2.5
}

src_install() {
	emake DESTDIR="${D}" install || die

	local x
	for x in aclocal automake ; do
		help2man "perl -Ilib ${x}" > ${x}-${SLOT}.1
		doman ${x}-${SLOT}.1
		rm -f "${D}"/usr/bin/${x}
	done

	dodoc NEWS README THANKS TODO AUTHORS ChangeLog
	doinfo doc/*.info*

	# remove all config.guess and config.sub files replacing them
	# w/a symlink to a specific gnuconfig version
	for x in guess sub ; do
		dosym ../gnuconfig/config.${x} /usr/share/${PN}-${SLOT}/config.${x}
	done
}
