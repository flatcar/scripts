# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-apps/xlsclients/xlsclients-1.1.2.ebuild,v 1.8 2011/08/20 15:50:41 jer Exp $

EAPI=4

inherit xorg-2

DESCRIPTION="X.Org xlsclients application"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE=""

RDEPEND="
	>=x11-libs/libxcb-1.7
	>=x11-libs/xcb-util-0.3.8
"
DEPEND="${RDEPEND}"
