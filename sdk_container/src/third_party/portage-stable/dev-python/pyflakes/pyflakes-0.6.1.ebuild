# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/pyflakes/pyflakes-0.6.1.ebuild,v 1.4 2013/07/03 03:37:06 floppym Exp $

EAPI="3"
PYTHON_DEPEND="2"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.*"
PYTHON_TESTS_RESTRICTED_ABIS="*-jython 2.7-pypy-1.*"
DISTUTILS_SRC_TEST="trial"

inherit distutils

DESCRIPTION="Passive checker for Python programs"
HOMEPAGE="https://launchpad.net/pyflakes http://pypi.python.org/pypi/pyflakes"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86 ~amd64-linux ~arm-linux ~x86-linux ~x86-macos"
IUSE=""

DEPEND="dev-python/setuptools"
RDEPEND="${DEPEND}"

# permission denied test needs FEATURES="userpriv" to work *sigh*
# rest is just confused and needs a good sedding to work
src_prepare() {
	sed -i -e 's/unittest2/unittest/' pyflakes/test/* || die
}
