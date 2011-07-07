# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-apps/xrandr/xrandr-1.3.4.ebuild,v 1.9 2011/02/14 23:41:03 xarthisius Exp $

EAPI=3

inherit xorg-2

DESCRIPTION="primitive command line interface to RandR extension"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux"
IUSE=""

RDEPEND=">=x11-libs/libXrandr-1.3
	x11-libs/libXrender
	x11-libs/libX11"
DEPEND="${RDEPEND}"

src_install() {
	xorg-2_src_install
	rm -f "${ED}"/usr/bin/xkeystone
}
