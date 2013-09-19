# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/udev/udev-206-r2.ebuild,v 1.1 2013/08/09 19:23:02 ssuominen Exp $

EAPI=5
inherit multilib-build

DESCRIPTION="Virtual to select between sys-fs/udev and sys-fs/eudev"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
# These default enabled IUSE flags should follow defaults of sys-fs/udev.
IUSE="gudev introspection +kmod selinux static-libs"

DEPEND=""
RDEPEND="|| ( >=sys-fs/udev-206-r2[${MULTILIB_USEDEP},gudev?,introspection?,kmod?,selinux?,static-libs?]
	>=sys-apps/systemd-206[${MULTILIB_USEDEP},gudev?,introspection?,kmod?,selinux?,static-libs(-)?]
	kmod? ( >=sys-fs/eudev-1.2-r1[${MULTILIB_USEDEP},keymap,modutils,gudev?,hwdb,introspection?,selinux?,static-libs?] )
	!kmod? ( >=sys-fs/eudev-1.2-r1[${MULTILIB_USEDEP},keymap,gudev?,hwdb,introspection?,selinux?,static-libs?] )
	)"
