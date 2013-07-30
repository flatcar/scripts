# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/six/six-1.2.0.ebuild,v 1.3 2012/10/06 01:26:56 blueness Exp $

EAPI="4"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="2.5-jython"
DISTUTILS_SRC_TEST="py.test"

inherit distutils

DESCRIPTION="Python 2 and 3 compatibility library"
HOMEPAGE="http://pypi.python.org/pypi/six"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ia64 ~ppc ~ppc64 ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~x86-macos"
IUSE="doc"

DEPEND="doc? ( dev-python/sphinx )"

PYTHON_MODNAME="${PN}.py"

src_prepare() {
	distutils_src_prepare

	# disable tests that require tkinter
	sed -i "s/test_move_items/_\0/" test_six.py || die
}

src_compile() {
	distutils_src_compile
	use doc && emake -C documentation html
}

src_install() {
	distutils_src_install
	use doc && dohtml -r documentation/_build/html/*
}
