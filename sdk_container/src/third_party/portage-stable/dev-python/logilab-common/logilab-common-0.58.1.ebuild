# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/logilab-common/logilab-common-0.58.1.ebuild,v 1.7 2013/01/06 18:57:00 mgorny Exp $

EAPI="3"
SUPPORT_PYTHON_ABIS="1"

inherit distutils

DESCRIPTION="Useful miscellaneous modules used by Logilab projects"
HOMEPAGE="http://www.logilab.org/project/logilab-common http://pypi.python.org/pypi/logilab-common"
SRC_URI="ftp://ftp.logilab.org/pub/common/${P}.tar.gz mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ~ia64 ppc ~ppc64 ~s390 ~sparc x86 ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
IUSE="test"

# dev-python/unittest2 is not required with Python >=3.2.
RDEPEND="dev-python/setuptools
	virtual/python-unittest2"

# Tests using dev-python/psycopg are skipped when dev-python/psycopg isn't installed.
DEPEND="${RDEPEND}
	test? (
		dev-python/egenix-mx-base
		!dev-python/psycopg[-mxdatetime]
	)"

PYTHON_MODNAME="logilab"

src_test() {
	testing() {
		# Install temporarily.
		local tpath="${T}/test-${PYTHON_ABI}"
		local spath="${tpath}${EPREFIX}$(python_get_sitedir)"

		"$(PYTHON)" setup.py build -b "build-${PYTHON_ABI}" install --root="${tpath}" || die "Installation for tests failed with $(python_get_implementation) $(python_get_version)"

		# pytest uses tests placed relatively to the current directory.
		pushd "${spath}" > /dev/null || return 1
		if [[ "${PYTHON_ABI}" == 3.* ]]; then
			# Support for Python 3 is experimental. Some tests are known to fail.
			PYTHONPATH="${spath}" "$(PYTHON)" "${tpath}${EPREFIX}/usr/bin/pytest" -v
		else
			PYTHONPATH="${spath}" "$(PYTHON)" "${tpath}${EPREFIX}/usr/bin/pytest" -v || return 1
		fi
		popd > /dev/null || return 1
	}
	python_execute_function testing
}

src_install() {
	distutils_src_install

	python_generate_wrapper_scripts -E -f -q "${ED}usr/bin/pytest"

	doman doc/pytest.1 || die "doman failed"

	delete_tests() {
		rm -fr "${ED}$(python_get_sitedir)/${PN/-//}/test"
	}
	python_execute_function -q delete_tests
}
