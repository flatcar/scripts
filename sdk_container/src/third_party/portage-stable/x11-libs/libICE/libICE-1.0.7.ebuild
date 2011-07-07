# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libICE/libICE-1.0.7.ebuild,v 1.10 2011/06/22 18:24:07 grobian Exp $

EAPI=3
inherit xorg-2

DESCRIPTION="X.Org ICE library"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~x86-fbsd ~x64-freebsd ~x86-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE="doc ipv6"

RDEPEND="x11-libs/xtrans
	x11-proto/xproto"
DEPEND="${RDEPEND}
	doc? ( app-text/xmlto )"

pkg_setup() {
	xorg-2_pkg_setup

	CONFIGURE_OPTIONS="$(use_enable ipv6)
		$(use_enable doc docs)
		$(use_enable doc specs)
		$(use_with doc xmlto)
		--without-fop"
}
