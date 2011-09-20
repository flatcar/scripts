# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-apps/xset/xset-1.2.1-r1.ebuild,v 1.7
# 2011/04/16 17:57:06 armin76 Exp $

EAPI=3

inherit xorg-2

DESCRIPTION="X.Org xset application"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux ~x86-macos ~x64-solaris ~x86-solaris"
IUSE=""

RDEPEND="
	x11-libs/libX11
	x11-libs/libXmu
	x11-libs/libXext"
DEPEND="${RDEPEND}"

pkg_setup() {
	CONFIGURE_OPTIONS="--without-xf86misc --without-fontcache"
	xorg-2_pkg_setup
}
