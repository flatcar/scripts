# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/logilab-common/logilab-common-0.59.0.ebuild,v 1.2 2013/02/02 18:54:18 mgorny Exp $

EAPI=5
# broken with python3.3, bug #449276
PYTHON_COMPAT=( python{2_6,2_7,3_2} pypy{1_9,2_0} )

inherit distutils-r1

DESCRIPTION="Useful miscellaneous modules used by Logilab projects"
HOMEPAGE="http://www.logilab.org/project/logilab-common http://pypi.python.org/pypi/logilab-common"
SRC_URI="ftp://ftp.logilab.org/pub/common/${P}.tar.gz mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~ia64 ~ppc ~ppc64 ~s390 ~sparc ~x86 ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
IUSE="test doc"

RDEPEND="dev-python/setuptools[${PYTHON_USEDEP}]
	virtual/python-unittest2[${PYTHON_USEDEP}]"

# Tests using dev-python/psycopg are skipped when dev-python/psycopg
# isn't installed.
# egenix-mx-base tests are optional, and egenix-mx-base does support
# Python2 only.
DEPEND="${RDEPEND}
	test? (
		dev-python/egenix-mx-base[$(python_gen_usedep 'python2*')]
		!dev-python/psycopg[-mxdatetime]
	)
	doc? ( dev-python/epydoc )"

python_prepare_all() {
	sed -e 's:(CURDIR):{S}/${P}:' -i doc/makefile || die
	distutils-r1_python_prepare_all
}

python_compile_all() {
	if use doc; then
		# Simplest way to make makefile point to the right place.
		ln -s "${BUILD_DIR}" build || die
		emake -C doc epydoc
		rm build || die
	fi
}

python_test() {
	# The package has to be 'installed' before testing.
	# 1) because of namespaces, we can't use 'install --root',
	# 2) 'install --home' is terribly broken on pypy,
	# 3) non-root 'install' complains about PYTHONPATH and missing dirs,
	#    so we need to set it properly and mkdir them,
	# 4) it runs a bunch of commands which write random files to cwd,
	#    in order to avoid that, we need to run them ourselves to pass
	#    alternate build paths,
	# 5) 'install' needs to go before 'bdist_egg' or the latter would
	#    re-set install paths.

	local tpath=${BUILD_DIR}/test
	local bindir=${tpath}/bin
	local libdir=${tpath}/lib
	local PYTHONPATH=${libdir}:${PYTHONPATH}

	mkdir -p "${libdir}" || die
	esetup.py egg_info --egg-base="${tpath}" \
		install --install-lib="${libdir}" --install-scripts="${bindir}" \
		bdist_egg --dist-dir="${tpath}"

	# Make sure that the tests use correct modules.
	cd "${libdir}" || die
	"${bindir}"/pytest || die "Tests fail with ${EPYTHON}"
}

python_install_all() {
	distutils-r1_python_install_all

	doman doc/pytest.1
	use doc && dohtml -r doc/apidoc/.
}
