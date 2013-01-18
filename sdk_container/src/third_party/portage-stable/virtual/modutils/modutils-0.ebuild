# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/modutils/modutils-0.ebuild,v 1.5 2012/05/10 01:43:26 vapier Exp $

EAPI="2"

DESCRIPTION="Virtual for utilities to manage Linux kernel modules"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86"
IUSE=""

DEPEND=""
RDEPEND="|| ( sys-apps/kmod[tools] >=sys-apps/module-init-tools-3.2 sys-apps/modutils )"
