# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-proto/bigreqsproto/bigreqsproto-1.1.1.ebuild,v 1.8 2011/02/14 14:26:53 xarthisius Exp $

EAPI=3
inherit xorg-2

DESCRIPTION="X.Org BigReqs protocol headers"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~x86-fbsd ~x64-freebsd ~ia64-hpux ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="doc"

RDEPEND=""
DEPEND="${RDEPEND}
	doc? ( app-text/xmlto )"

pkg_setup() {
	xorg-2_pkg_setup

	CONFIGURE_OPTIONS="$(use_enable doc specs)
		$(use_with doc xmlto)
		--without-fop"
}
