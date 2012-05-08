# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/pkgconfig/pkgconfig-0.ebuild,v 1.3 2012/05/04 13:05:26 ssuominen Exp $

EAPI="2"

DESCRIPTION="virtual for pkg-config"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

DEPEND="|| (
		dev-util/pkgconfig
		dev-util/pkg-config-lite
		dev-util/pkgconf[pkg-config]
		dev-util/pkgconfig-openbsd[pkg-config]
	)"
RDEPEND="${DEPEND}"
