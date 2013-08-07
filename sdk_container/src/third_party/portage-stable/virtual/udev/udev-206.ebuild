# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/udev/udev-206.ebuild,v 1.3 2013/08/02 12:40:35 blueness Exp $

EAPI=5

DESCRIPTION="Virtual to select between sys-fs/udev and sys-fs/eudev"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
# These default enabled IUSE flags should follow defaults of sys-fs/udev.
IUSE="gudev hwdb introspection +kmod selinux static-libs"

DEPEND=""
RDEPEND="|| ( >=sys-fs/udev-206[gudev?,hwdb?,introspection?,kmod?,selinux?,static-libs?]
	>=sys-apps/systemd-206[gudev?,introspection?,kmod?,selinux?,static-libs(-)?]
	kmod? ( >=sys-fs/eudev-1.2[keymap,modutils,gudev?,hwdb?,introspection?,selinux?,static-libs?] )
	!kmod? ( >=sys-fs/eudev-1.2[keymap,gudev?,hwdb?,introspection?,selinux?,static-libs?] )
	)"
