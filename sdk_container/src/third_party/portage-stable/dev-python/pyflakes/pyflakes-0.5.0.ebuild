# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/pyflakes/pyflakes-0.5.0.ebuild,v 1.9 2012/12/11 17:06:10 ago Exp $

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
KEYWORDS="amd64 ~ppc ~ppc64 x86 ~amd64-linux ~x86-linux ~x86-macos"
IUSE=""

DEPEND=""
RDEPEND=""
