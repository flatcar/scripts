# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/udev/udev-208-r2.ebuild,v 1.5 2014/06/18 20:58:26 mgorny Exp $

EAPI=5
inherit multilib-build

DESCRIPTION="Virtual to select between different udev daemon providers"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86"
# These default enabled IUSE flags should follow defaults of sys-fs/udev.
IUSE="gudev introspection static-libs"

DEPEND=""
RDEPEND="
	>=virtual/libudev-208:0/1[${MULTILIB_USEDEP},static-libs?]
	gudev? ( >=virtual/libgudev-208:0/0[${MULTILIB_USEDEP},introspection?,static-libs?] )

	|| (
		>=sys-fs/udev-208
		>=sys-apps/systemd-208:0
		>=sys-fs/eudev-1.3
	)"
