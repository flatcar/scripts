# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/six/six-1.2.0-r1.ebuild,v 1.3 2013/01/02 04:40:19 floppym Exp $

EAPI=5
PYTHON_COMPAT=( python{2_5,2_6,2_7,3_1,3_2,3_3} pypy{1_8,1_9,2_0} )

inherit distutils-r1

DESCRIPTION="Python 2 and 3 compatibility library"
HOMEPAGE="https://bitbucket.org/gutworth/six http://pypi.python.org/pypi/six"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ia64 ~ppc ~ppc64 ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~x86-macos"
IUSE="doc test"

DEPEND="doc? ( dev-python/sphinx )
	test? ( dev-python/pytest[${PYTHON_USEDEP}] )"

python_prepare_all() {
	# disable tests that require tkinter
	sed -i -e "s/test_move_items/_&/" test_six.py || die

	distutils-r1_python_prepare_all
}

python_compile_all() {
	use doc && emake -C documentation html
}

python_test() {
	py.test || die "Testing failed with ${EPYTHON}"
}

python_install_all() {
	use doc && local HTML_DOCS=( documentation/_build/html/ )

	distutils-r1_python_install_all
}
