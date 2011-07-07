# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-proto/xf86dgaproto/xf86dgaproto-2.1.ebuild,v 1.10 2010/08/02 18:14:35 armin76 Exp $

inherit x-modular

DESCRIPTION="X.Org XF86DGA protocol headers"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris"
IUSE=""

RDEPEND="!<x11-libs/libXxf86dga-1.0.99.1"
DEPEND="${RDEPEND}"
