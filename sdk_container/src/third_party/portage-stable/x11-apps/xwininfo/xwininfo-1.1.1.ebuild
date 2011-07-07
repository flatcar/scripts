# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-apps/xwininfo/xwininfo-1.1.1.ebuild,v 1.10 2011/06/15 11:46:32 mduft Exp $

EAPI=3

inherit xorg-2 flag-o-matic

DESCRIPTION="window information utility for X"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE=""

RDEPEND=">=x11-libs/libxcb-1.6
	x11-libs/libX11"
DEPEND="${RDEPEND}
	>=x11-proto/xproto-7.0.17"

pkg_setup() {
	# interix has a _very_ old iconv in libc, however, including
	# iconv.h redefines those symbols to libiconv_*, which then
	# are unresolved, as the configure check is old and dumb.
	[[ ${CHOST} == *-interix* ]] &&
		append-libs -liconv
}
