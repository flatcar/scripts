# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-apps/xlsclients/xlsclients-1.1.1.ebuild,v 1.10 2011/02/14 18:43:22 xarthisius Exp $

EAPI=3

inherit xorg-2

DESCRIPTION="X.Org xlsclients application"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE=""

RDEPEND="
	x11-libs/libxcb
	x11-libs/xcb-util
"
DEPEND="${RDEPEND}"
