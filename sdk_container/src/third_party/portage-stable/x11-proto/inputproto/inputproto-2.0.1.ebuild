# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-proto/inputproto/inputproto-2.0.1.ebuild,v 1.8 2011/03/15 21:12:16 xarthisius Exp $

EAPI=3
inherit xorg-2

DESCRIPTION="X.Org Input protocol headers"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~x86-fbsd ~x64-freebsd ~x86-freebsd ~ia64-hpux ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE=""

RDEPEND=""
DEPEND="${RDEPEND}
!<x11-libs/libXi-1.2.99"
