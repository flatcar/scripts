# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-apps/xev/xev-1.1.0.ebuild,v 1.9 2011/02/14 18:52:31 xarthisius Exp $

EAPI=3

inherit xorg-2

DESCRIPTION="print contents of X events"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux ~x86-winnt"
IUSE=""

RDEPEND="x11-libs/libX11"
DEPEND="${RDEPEND}"
