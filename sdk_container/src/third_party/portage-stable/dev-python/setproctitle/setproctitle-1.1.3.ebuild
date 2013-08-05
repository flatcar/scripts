# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/setproctitle/setproctitle-1.1.3.ebuild,v 1.5 2013/03/01 09:12:16 swegener Exp $

EAPI="3"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="*-jython"
DISTUTILS_SRC_TEST="nosetests"

inherit distutils toolchain-funcs

DESCRIPTION="Allow customization of the process title."
HOMEPAGE="http://code.google.com/p/py-setproctitle/ http://pypi.python.org/pypi/setproctitle"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 ~arm ~sparc x86"
IUSE=""

DEPEND=""
RDEPEND=""

DISTUTILS_USE_SEPARATE_SOURCE_DIRECTORIES="1"
DOCS="HISTORY README"

src_prepare() {
	python_copy_sources

	conversion() {
		[[ "${PYTHON_ABI}" == 2.* ]] && return
		2to3-${PYTHON_ABI} -w --no-diffs tests > /dev/null
	}
	python_execute_function \
		--action-message 'Applying patches for $(python_get_implementation) $(python_get_version)' \
		--failure-message 'Applying patches for $(python_get_implementation) $(python_get_version) failed' \
		-s conversion
}

distutils_src_test_pre_hook() {
	ln -fs pyrun-${PYTHON_ABI} tests/pyrun
}

src_test() {
	build_pyrun() {
		echo $(tc-getCC) ${CPPFLAGS} ${CFLAGS} ${LDFLAGS} -I$(python_get_includedir) -o tests/pyrun-${PYTHON_ABI} tests/pyrun.c $(python_get_library -l)
		$(tc-getCC) ${CPPFLAGS} ${CFLAGS} ${LDFLAGS} -I$(python_get_includedir) -o tests/pyrun-${PYTHON_ABI} tests/pyrun.c $(python_get_library -l)
	}
	python_execute_function -q -s build_pyrun

	distutils_src_test
}
