# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/python-xlib/python-xlib-0.14.ebuild,v 1.7 2009/11/14 16:35:31 armin76 Exp $

inherit distutils

DESCRIPTION="A fully functional X client library for Python, written in Python"
HOMEPAGE="http://python-xlib.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 ~arm ia64 ppc ~ppc64 x86"
IUSE="doc"
DEPEND="${RDEPEND}
	doc? ( virtual/latex-base
		>=sys-apps/texinfo-4.8-r2 )"

PYTHON_MODNAME="Xlib"

src_compile() {
	distutils_src_compile
	if use doc; then
		cd doc
		VARTEXFONTS="${T}"/fonts emake || die "make docs failed"
	fi
}

src_install () {
	distutils_src_install
	if use doc; then
		dohtml -r doc/html/
		dodoc doc/ps/python-xlib.ps
	fi
}

src_test() {
	distutils_python_version
	for pytest in $(ls test/*py); do
		PYTHONPATH=. "${python}" ${pytest} || die "test failed"
	done
}
