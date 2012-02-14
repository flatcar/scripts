# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-fonts/encodings/encodings-1.0.3.ebuild,v 1.10 2010/01/19 17:57:22 armin76 Exp $

# Must be before x-modular eclass is inherited
#SNAPSHOT="yes"

inherit x-modular

DESCRIPTION="X.Org font encodings"

KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE=""

RDEPEND=""
DEPEND="${RDEPEND}
	x11-apps/mkfontscale"

CONFIGURE_OPTIONS="--with-encodingsdir=/usr/share/fonts/encodings"

ECONF_SOURCE="${S}"

src_compile() {
	mkdir "${S}"/build
	cd "${S}"/build
	x-modular_src_compile
}

src_install() {
	cd "${S}"/build
	x-modular_src_install
}
