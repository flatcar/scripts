# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-apps/xhost/xhost-1.0.4.ebuild,v 1.9 2011/02/14 23:41:03 xarthisius Exp $

EAPI=3

inherit xorg-2

DESCRIPTION="Controls host and/or user access to a running X server."

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="ipv6"

RDEPEND="x11-libs/libX11
	x11-libs/libXmu
	x11-libs/libXau"
DEPEND="${RDEPEND}"

pkg_setup() {
	CONFIGURE_OPTIONS="$(use_enable ipv6)"
}
