# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-apps/iceauth/iceauth-1.0.4.ebuild,v 1.9 2011/02/14 14:52:25 xarthisius Exp $

EAPI=3

inherit xorg-2

DESCRIPTION="ICE authority file utility"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x86-solaris ~x86-winnt"
IUSE=""

RDEPEND="x11-libs/libICE"
DEPEND="${RDEPEND}
	x11-proto/xproto"
