# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/markdown/markdown-2.2.1-r1.ebuild,v 1.10 2014/03/31 20:54:31 mgorny Exp $

EAPI=5
# python3.3 because of dev-python/pygments
PYTHON_COMPAT=( python{2_6,2_7,3_2} pypy pypy2_0 )

inherit distutils-r1

MY_PN="Markdown"
MY_P=${MY_PN}-${PV}

DESCRIPTION="Python implementation of the markdown markup language"
HOMEPAGE="http://www.freewisdom.org/projects/python-markdown http://pypi.python.org/pypi/Markdown"
SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"

LICENSE="|| ( BSD GPL-2 )"
SLOT="0"
KEYWORDS="alpha amd64 ~arm ia64 ppc sparc x86 ~ppc-macos ~x86-macos"
IUSE="doc test pygments"

DEPEND="test? ( dev-python/nose[${PYTHON_USEDEP}] )"
RDEPEND="pygments? ( dev-python/pygments[${PYTHON_USEDEP}] )"

S="${WORKDIR}/${MY_P}"

python_prepare_all() {
	# do not build docs over and over again
	sed -i -e "/'build':/s:md_build:build:" setup.py || die

	distutils-r1_python_prepare_all
}

python_compile_all() {
	use doc && esetup.py build_docs
}

python_install_all() {
	if use doc; then
		local DOCS=( docs/. )

		# templates which we don't want in docdir
		rm -f docs/*.{html,css,png}
	fi

	distutils-r1_python_install_all
}

python_test() {
	cp -r -l run-tests.py tests "${BUILD_DIR}"/ || die
	cd "${BUILD_DIR}" || die

	if [[ ${EPYTHON} == python3* ]]; then
		# don't use -n: it causes writes to hardlinked files
		2to3 -w --no-diffs tests || die
	fi

	"${PYTHON}" run-tests.py || die "Tests fail with ${EPYTHON}"
}
