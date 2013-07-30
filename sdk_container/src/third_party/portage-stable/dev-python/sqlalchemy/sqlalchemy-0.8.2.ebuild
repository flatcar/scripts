# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/sqlalchemy/sqlalchemy-0.8.2.ebuild,v 1.1 2013/07/08 05:51:58 patrick Exp $

EAPI=5
PYTHON_COMPAT=( python{2_5,2_6,2_7,3_2,3_3} pypy{1_9,2_0} )

inherit distutils-r1 eutils flag-o-matic

MY_PN="SQLAlchemy"
MY_P="${MY_PN}-${PV/_}"

DESCRIPTION="Python SQL toolkit and Object Relational Mapper"
HOMEPAGE="http://www.sqlalchemy.org/ http://pypi.python.org/pypi/SQLAlchemy"
SRC_URI="mirror://pypi/${MY_P:0:1}/${MY_PN}/${MY_P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd \
	~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
IUSE="doc examples +sqlite test"

RDEPEND="dev-python/setuptools[${PYTHON_USEDEP}]
		sqlite? ( >=dev-db/sqlite-3.3.13 )"

DEPEND="${RDEPEND}
	test? (
		>=dev-db/sqlite-3.3.13
		>=dev-python/nose-0.10.4[${PYTHON_USEDEP}]
		dev-python/mock[${PYTHON_USEDEP}]
	)"

S="${WORKDIR}/${MY_P}"

# Required for testsuite, mainly py3
DISTUTILS_IN_SOURCE_BUILD=1

python_prepare() {
	# Disable tests hardcoding function call counts specific to Python versions.
	if [[ "${EPYTHON}" == 'python2.5' || "${EPYTHON}" == 'python2.6' ]]; then
		rm -fr test/aaa_profiling
	fi
}

python_configure() {
	if [[ "${EPYTHON}" != python3* ]]; then
		append-flags -fno-strict-aliasing
	fi
}

python_test() {
	local DISTUTILS_NO_PARALLEL_BUILD=1
	# No longer has postgresql support
	if [[ "${EPYTHON}" == python3* ]]; then
		"${PYTHON}" sa2to3.py --no-diffs -w lib test examples
	fi
	"${PYTHON}" sqla_nose.py -I test_postgresql || die "Testsuite failed under ${EPYTHON}"
}

python_install_all() {
	use doc && HTML_DOCS=( doc/. )

	use examples && local EXAMPLES=( examples )

	distutils-r1_python_install_all
}

pkg_postinst() {
	if [[ -z ${REPLACING_VERSIONS} ]]; then
		if ! has_version dev-python/mysql-python; then
		        elog "For MySQL support, install dev-python/mysql-python"
		fi

		if ! has_version dev-python/pymssql; then
			elog "For mssql support, install dev-python/pymssql"
		fi

		if ! has_version dev-python/psycopg:2; then
			elog "For postgresql support, install dev-python/psycopg:2"
		fi
	fi
}
