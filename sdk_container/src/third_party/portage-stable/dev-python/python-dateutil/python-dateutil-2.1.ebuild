# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/python-dateutil/python-dateutil-2.1.ebuild,v 1.7 2012/12/17 17:53:41 ago Exp $

EAPI="4"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="2.5 *-pypy-*"

inherit distutils eutils

DESCRIPTION="Extensions to the standard Python datetime module"
HOMEPAGE="https://launchpad.net/dateutil http://pypi.python.org/pypi/python-dateutil"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 ia64 ppc ~ppc64 x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
IUSE="examples"

RDEPEND="dev-python/six
	sys-libs/timezone-data
	!<dev-python/python-dateutil-2.1"
DEPEND="${RDEPEND}
	dev-python/setuptools"

DOCS="NEWS README"
PYTHON_MODNAME="dateutil"

src_prepare() {
	# Bug 410725.
	epatch "${FILESDIR}/${P}-open-utf-8.patch"

	# Use zoneinfo in /usr/share/zoneinfo.
	sed -i -e "s/zoneinfo.gettz/gettz/g" test.py || die

	# Fix parsing of date in non-English locales.
	sed -e 's/subprocess.getoutput("date")/subprocess.getoutput("LC_ALL=C date")/' \
		-i example.py || die

	distutils_src_prepare
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
		rm -f "${ED}$(python_get_sitedir)/dateutil/zoneinfo"/*.tar.*
	}
	python_execute_function -q delete_zoneinfo

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins example.py sandbox/*.py
	fi
}
