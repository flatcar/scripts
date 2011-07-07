# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-apps/xcursorgen/xcursorgen-1.0.4.ebuild,v 1.9 2011/02/14 23:02:32 xarthisius Exp $

EAPI=3

inherit xorg-2

DESCRIPTION="create an X cursor file from a collection of PNG images"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE=""

RDEPEND="media-libs/libpng
	x11-libs/libX11
	x11-libs/libXcursor"
DEPEND="${RDEPEND}"
