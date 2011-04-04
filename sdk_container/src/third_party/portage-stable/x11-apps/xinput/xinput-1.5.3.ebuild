# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-apps/xinput/xinput-1.5.3.ebuild,v 1.8 2011/02/14 23:41:02 xarthisius Exp $

EAPI=3

inherit xorg-2

DESCRIPTION="Utility to set XInput device parameters"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd"
IUSE=""

RDEPEND=">=x11-libs/libX11-1.3
	x11-libs/libXext
	>=x11-libs/libXi-1.3"
DEPEND="${RDEPEND}
	>=x11-proto/inputproto-2.0"
