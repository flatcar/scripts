# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/udev/udev-197-r3.ebuild,v 1.1 2013/04/17 11:01:16 mgorny Exp $

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
RDEPEND="|| ( >=sys-fs/udev-197-r8[gudev?,hwdb?,introspection?,keymap?,kmod?,selinux?,static-libs?]
	>=sys-apps/systemd-198-r5[gudev?,introspection?,keymap(+)?,kmod?,selinux?,static-libs?]
	kmod? ( >=sys-fs/eudev-1_beta2-r2[modutils,gudev?,hwdb?,introspection?,keymap?,selinux?,static-libs?] )
	!kmod? ( >=sys-fs/eudev-1_beta2-r2[gudev?,hwdb?,introspection?,keymap?,selinux?,static-libs?] )
	)"
