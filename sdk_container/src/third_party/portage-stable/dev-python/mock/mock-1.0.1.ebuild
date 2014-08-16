# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/mock/mock-1.0.1.ebuild,v 1.4 2014/07/06 12:45:23 mgorny Exp $

EAPI="3"
SUPPORT_PYTHON_ABIS="1"
DISTUTILS_SRC_TEST="nosetests"

inherit distutils

DESCRIPTION="A Python Mocking and Patching Library for Testing"
HOMEPAGE="http://www.voidspace.org.uk/python/mock/ http://pypi.python.org/pypi/mock"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~x64-macos ~x86-linux"
IUSE="doc test"

# dev-python/unittest2 is not required with Python >=3.2.
DEPEND="dev-python/setuptools"
RDEPEND=""

DOCS="docs/*.txt"
PYTHON_MODNAME="mock.py"

src_install() {
	distutils_src_install

	if use doc; then
		pushd html > /dev/null
		rm -f objects.inv output.txt
		insinto /usr/share/doc/${PF}/html
		doins -r [a-z]* _static || die "Installation of documentation failed"
		popd > /dev/null
	fi
}
