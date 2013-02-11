# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libXtst/libXtst-1.2.1.ebuild,v 1.9 2012/08/26 18:45:13 armin76 Exp $

EAPI=4

XORG_DOC="doc"
inherit xorg-2

DESCRIPTION="X.Org Xtst library"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE=""

RDEPEND="x11-libs/libX11
	>=x11-libs/libXext-1.0.99.4
	x11-libs/libXi
	>=x11-proto/recordproto-1.13.99.1
	>=x11-proto/xextproto-7.0.99.3
	x11-proto/inputproto"
DEPEND="${RDEPEND}"
