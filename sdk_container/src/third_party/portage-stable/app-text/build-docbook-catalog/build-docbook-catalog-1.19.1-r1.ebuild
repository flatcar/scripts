# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/build-docbook-catalog/build-docbook-catalog-1.19.1-r1.ebuild,v 1.2 2014/01/18 11:46:00 vapier Exp $

EAPI=5

inherit eutils

DESCRIPTION="DocBook XML catalog auto-updater"
HOMEPAGE="http://sources.gentoo.org/gentoo-src/build-docbook-catalog/"
SRC_URI="mirror://gentoo/${P}.tar.xz
	http://dev.gentoo.org/~floppym/distfiles/${P}.tar.xz
	http://dev.gentoo.org/~vapier/dist/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~ppc-aix ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~ia64-hpux ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="userland_BSD kernel_linux"

RDEPEND="kernel_linux? ( sys-apps/util-linux )
	!kernel_linux? ( app-misc/getopt )
	!<app-text/docbook-xsl-stylesheets-1.73.1
	userland_BSD? ( sys-apps/flock )
	dev-libs/libxml2"
DEPEND=""

src_prepare() {
	if use prefix ; then
		sed -i -e "/^\(ROOTCONFDIR\|DOCBOOKDIR\)=/s:=/:=${EPREFIX}/:" build-docbook-catalog || die
		sed -i -e "/^\(SYSCONFDIR\|PREFIX\) = /s:= /:= ${EPREFIX}/:" Makefile || die
		if use !kernel_linux ; then
			sed -i -e '/opts=/s/getopt/getopt-long/' build-docbook-catalog || die
		fi
		epatch "${FILESDIR}"/${P}-no-flock.patch  # obsoletes flock requirement
	fi
}

pkg_postinst() {
	# New version -> regen files
	build-docbook-catalog
}
