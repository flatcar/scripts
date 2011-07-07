# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libXvMC/libXvMC-1.0.6.ebuild,v 1.8 2011/02/14 23:22:40 xarthisius Exp $

EAPI=3

inherit xorg-2

DESCRIPTION="X.Org XvMC library"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x86-solaris"
IUSE=""

RDEPEND="x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXv
	x11-proto/videoproto
	x11-proto/xextproto"
DEPEND="${RDEPEND}"
PDEPEND="app-admin/eselect-xvmc"
