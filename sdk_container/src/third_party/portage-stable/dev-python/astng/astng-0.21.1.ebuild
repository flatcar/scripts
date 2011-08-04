# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/astng/astng-0.21.1.ebuild,v 1.1 2011/01/17 22:53:07 arfrever Exp $

EAPI="3"
SUPPORT_PYTHON_ABIS="1"

inherit distutils

DESCRIPTION="Abstract Syntax Tree New Generation for logilab packages"
HOMEPAGE="http://www.logilab.org/projects/astng/ http://pypi.python.org/pypi/logilab-astng"
SRC_URI="ftp://ftp.logilab.org/pub/astng/logilab-${P}.tar.gz mirror://pypi/l/logilab-astng/logilab-${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x64-macos ~x86-macos"
IUSE="test"

# Version specified in __pkginfo__.py.
RDEPEND=">=dev-python/logilab-common-0.53.0"
DEPEND="${RDEPEND}
	dev-python/setuptools
	test? ( >=dev-python/egenix-mx-base-3.0.0 )"

S="${WORKDIR}/logilab-${P}"

DISTUTILS_USE_SEPARATE_SOURCE_DIRECTORIES="1"

PYTHON_MODNAME="logilab/astng"

src_prepare() {
	distutils_src_prepare

	conversion() {
		[[ "${PYTHON_ABI}" == 2.* ]] && return
		find -name "*.py" ! -name "setup.py" -print | xargs 2to3-${PYTHON_ABI} -nw --no-diffs
	}
	python_execute_function -s conversion
}

src_test() {
	testing() {
		local tpath="${T}/test-${PYTHON_ABI}"
		local spath="${tpath}$(python_get_sitedir)"

		mkdir -p "${spath}/logilab" || return 1
		cp -r "$(python_get_sitedir)/logilab/common" "${spath}/logilab" || return 1

		"$(PYTHON)" setup.py install --root="${tpath}" || die "Installation for tests failed with $(python_get_implementation) $(python_get_version)"

		# pytest uses tests placed relatively to the current directory.
		pushd "${spath}/logilab/astng" > /dev/null || return 1
		if [[ "${PYTHON_ABI}" == 3.* ]]; then
			# Support for Python 3 is experimental. Some tests are known to fail.
			PYTHONPATH="${spath}" pytest -v
		else
			PYTHONPATH="${spath}" pytest -v || return 1
		fi
		popd > /dev/null || return 1
	}
	python_execute_function -s testing
}

src_install() {
	distutils_src_install

	deletion_of_unneeded_files() {
		# Avoid collision with dev-python/logilab-common.
		rm -f "${ED}$(python_get_sitedir)/logilab/__init__.py" || return 1

		# Don't install tests.
		rm -fr "${ED}$(python_get_sitedir)/logilab/astng/test" || return 1
	}
	python_execute_function -q deletion_of_unneeded_files
}
