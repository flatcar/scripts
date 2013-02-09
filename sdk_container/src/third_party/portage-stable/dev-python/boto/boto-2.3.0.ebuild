# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/boto/boto-2.3.0.ebuild,v 1.8 2012/07/29 16:59:38 armin76 Exp $

EAPI="4"
PYTHON_DEPEND="2:2.5"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="2.4 3.*"
DISTUTILS_SRC_TEST="setup.py"

inherit distutils

DESCRIPTION="Amazon Web Services API"
HOMEPAGE="https://github.com/boto/boto http://pypi.python.org/pypi/boto"
SRC_URI="mirror://github/boto/boto/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ppc sparc x86 ~x86-linux ~ppc-macos ~x86-macos"
IUSE="test"

DEPEND="dev-python/setuptools
	test? ( dev-python/m2crypto )"
RDEPEND="dev-python/m2crypto"

# Requires Amazon Web Services keys to pass some tests
RESTRICT="test"
