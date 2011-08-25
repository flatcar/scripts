# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/yacc/yacc-0.ebuild,v 1.2 2011/08/15 13:04:46 nirbheek Exp $

DESCRIPTION="virtual for yacc (yet another compiler compiler)"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE=""

DEPEND="|| ( sys-devel/bison dev-util/yacc )"
RDEPEND="${DEPEND}"
