# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/os-headers/os-headers-0.ebuild,v 1.4 2011/05/09 20:11:43 ulm Exp $

EAPI=1

DESCRIPTION="Virtual for operating system headers"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

DEPEND=""
# depend on SLOT 0 of linux-headers, because kernel-2.eclass
# sets a different SLOT for cross-building
RDEPEND="!prefix? (
		|| ( sys-kernel/linux-headers:0
			sys-freebsd/freebsd-lib )
	)"
