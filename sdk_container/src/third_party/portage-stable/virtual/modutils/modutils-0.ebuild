# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/modutils/modutils-0.ebuild,v 1.6 2013/07/23 11:14:54 ssuominen Exp $

EAPI=5

DESCRIPTION="Virtual for utilities to manage Linux kernel modules"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86"
IUSE=""

DEPEND=""
RDEPEND="|| ( sys-apps/kmod[tools] sys-apps/modutils )"
