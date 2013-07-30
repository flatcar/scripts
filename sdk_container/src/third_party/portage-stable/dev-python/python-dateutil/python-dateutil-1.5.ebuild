# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/python-dateutil/python-dateutil-1.5.ebuild,v 1.7 2011/11/26 16:26:21 hwoarang Exp $

EAPI="3"
PYTHON_DEPEND="2"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.*"
PYTHON_TESTS_FAILURES_TOLERANT_ABIS="*-jython"

inherit distutils

DESCRIPTION="Extensions to the standard Python datetime module"
HOMEPAGE="http://labix.org/python-dateutil http://pypi.python.org/pypi/python-dateutil"
SRC_URI="http://labix.org/download/python-dateutil/${P}.tar.gz"

LICENSE="PSF-2"
SLOT="python-2"
KEYWORDS="amd64 ia64 ppc ~ppc64 x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
IUSE="examples"

RDEPEND="sys-libs/timezone-data"
DEPEND="${RDEPEND}
	dev-python/setuptools"

DOCS="NEWS README"
PYTHON_MODNAME="dateutil"

src_prepare() {
	distutils_src_prepare

	# Use zoneinfo in /usr/share/zoneinfo.
	sed -e "s/zoneinfo.gettz/gettz/g" -i test.py || die "sed failed"

	# Fix parsing of date in non-English locales.
	sed -e 's/commands.getoutput("date")/commands.getoutput("LC_ALL=C date")/' -i example.py
}

src_test() {
	testing() {
		PYTHONPATH="build-${PYTHON_ABI}/lib" "$(PYTHON)" test.py
	}
	python_execute_function testing
}

src_install() {
	distutils_src_install

	delete_zoneinfo() {
		rm -f "${ED}$(python_get_sitedir)/dateutil/zoneinfo/"*.tar.*
	}
	python_execute_function -q delete_zoneinfo

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins example.py sandbox/*.py
	fi
}
