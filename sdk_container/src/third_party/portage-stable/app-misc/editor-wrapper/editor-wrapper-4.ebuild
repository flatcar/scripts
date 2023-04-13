# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-misc/editor-wrapper/editor-wrapper-4.ebuild,v 1.7 2011/12/29 21:37:29 ulm Exp $

EAPI=4

DESCRIPTION="Wrapper scripts that will execute EDITOR or PAGER"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI=""

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE=""

S="${WORKDIR}"

src_prepare() {
	sed -e 's/@VAR@/EDITOR/g' "${FILESDIR}/${P}.sh" >editor || die
	sed -e 's/@VAR@/PAGER/g'  "${FILESDIR}/${P}.sh" >pager  || die
}

src_install() {
	exeinto /usr/libexec
	doexe editor pager
}
