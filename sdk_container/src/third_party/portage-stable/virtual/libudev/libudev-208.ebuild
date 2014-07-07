# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/libudev/libudev-208.ebuild,v 1.4 2014/06/18 20:57:13 mgorny Exp $

EAPI=5
inherit multilib-build

DESCRIPTION="Virtual for libudev providers"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0/1"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86"
IUSE="static-libs"

DEPEND=""
RDEPEND="
	|| (
		>=sys-fs/udev-208-r1:0/0[${MULTILIB_USEDEP},static-libs?]
		>=sys-apps/systemd-212-r5:0/2[${MULTILIB_USEDEP},static-libs(-)?]
		>=sys-apps/systemd-208-r3:0/1[${MULTILIB_USEDEP},static-libs(-)?]
		>=sys-apps/systemd-208:0/0[${MULTILIB_USEDEP},static-libs(-)?]
		>=sys-fs/eudev-1.3:0/0[${MULTILIB_USEDEP},static-libs?]
	)"
