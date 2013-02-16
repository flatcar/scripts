# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/shadow/shadow-0.ebuild,v 1.8 2012/08/05 12:08:34 grobian Exp $

DESCRIPTION="Virtual for user account management utilities"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~x64-freebsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

# >=shadow-4-1 is required because of bug #367633 (user.eclass needs it).
# On Prefix installations we sort of have to hope there is some shadow
# available, on UNIX-like (or emulated) systems this usually is the case.
DEPEND=""
RDEPEND="!prefix? ( || ( >=sys-apps/shadow-4.1 sys-apps/hardened-shadow ) )"
