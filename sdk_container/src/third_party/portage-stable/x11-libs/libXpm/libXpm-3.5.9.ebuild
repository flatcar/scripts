# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libXpm/libXpm-3.5.9.ebuild,v 1.12 2011/06/22 18:37:11 grobian Exp $

EAPI=3
inherit xorg-2 flag-o-matic

DESCRIPTION="X.Org Xpm library"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

RDEPEND="x11-libs/libX11
	x11-libs/libXt
	x11-libs/libXext
	x11-proto/xextproto
	x11-proto/xproto"
DEPEND="${RDEPEND}
	sys-devel/gettext"

src_configure() {
	# the gettext configure check and code in sxpm are incorrect; they assume
	# gettext being in libintl, whereas Solaris has gettext by default
	# resulting in libintl not being added to LIBS
	[[ ${CHOST} == *-solaris* ]] && append-libs -lintl
	xorg-2_src_configure
}

src_compile() {
	xorg-2_src_compile
}
