# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/gnulib/gnulib-9999-r1.ebuild,v 1.5 2011/09/21 08:21:11 mgorny Exp $

EGIT_REPO_URI="git://git.savannah.gnu.org/${PN}.git
	http://git.savannah.gnu.org/r/${PN}.git"

inherit eutils git-2

DESCRIPTION="Gnulib is a library of common routines intended to be shared at the source level."
HOMEPAGE="http://www.gnu.org/software/gnulib"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="doc"

DEPEND=""
RDEPEND=""

S="${WORKDIR}"/${PN}

src_compile() {
	if use doc; then
		emake -C doc info html || die "emake failed"
	fi
}

src_install() {
	dodoc README ChangeLog
	if use doc; then
		dohtml doc/gnulib.html
		doinfo doc/gnulib.info
	fi

	insinto /usr/share/${PN}
	doins -r lib
	doins -r m4
	doins -r modules
	doins -r build-aux
	doins -r top

	# install the real script
	exeinto /usr/share/${PN}
	doexe gnulib-tool

	# create and install the wrapper
	dosym /usr/share/${PN}/gnulib-tool /usr/bin/gnulib-tool
}
