# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/udev/udev-200.ebuild,v 1.2 2013/07/26 14:50:02 ssuominen Exp $

EAPI=5

DESCRIPTION="Virtual to select between sys-fs/udev and sys-fs/eudev"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86"
# These default enabled IUSE flags should follow defaults of sys-fs/udev.
IUSE="gudev hwdb introspection keymap +kmod selinux static-libs"

DEPEND=""
RDEPEND="|| ( >=sys-fs/udev-200[gudev?,hwdb?,introspection?,keymap?,kmod?,selinux?,static-libs?]
	>=sys-apps/systemd-200[gudev?,introspection?,keymap(+)?,kmod?,selinux?,static-libs(-)?]
	kmod? ( >=sys-fs/eudev-1[modutils,gudev?,hwdb?,introspection?,keymap?,selinux?,static-libs?] )
	!kmod? ( >=sys-fs/eudev-1[gudev?,hwdb?,introspection?,keymap?,selinux?,static-libs?] )
	)"
