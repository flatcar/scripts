# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/service-manager/service-manager-0.ebuild,v 1.5 2013/07/29 07:29:39 grobian Exp $

DESCRIPTION="Virtual for various service managers"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~ppc-aix ~x64-freebsd ~x86-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE="kernel_linux prefix"

RDEPEND="
	prefix? ( >=sys-apps/baselayout-prefix-2.2 )
	!prefix? (
		|| (
		sys-apps/openrc
		kernel_linux? ( || (
			sys-apps/systemd
			sys-process/runit
			virtual/daemontools
	) ) ) )"
DEPEND=""
