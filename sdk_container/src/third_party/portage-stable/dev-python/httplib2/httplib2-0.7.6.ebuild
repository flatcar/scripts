# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/httplib2/httplib2-0.7.6.ebuild,v 1.8 2012/12/30 20:25:48 ago Exp $

EAPI="4"
PYTHON_DEPEND="2 3:3.2"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.1"

RESTRICT="test" # tests connect to random remote sites and exploderate badly

inherit distutils

DESCRIPTION="A comprehensive HTTP client library"
HOMEPAGE="http://code.google.com/p/httplib2/ http://pypi.python.org/pypi/httplib2"
SRC_URI="http://httplib2.googlecode.com/files/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 ~arm ia64 ppc ppc64 sparc x86 ~amd64-linux ~x86-linux ~x64-macos"
IUSE=""

src_test() {
	testing() {
		pushd "python$(python_get_version --major)" > /dev/null
		"$(PYTHON)" httplib2test.py
		popd > /dev/null
	}
	python_execute_function testing
}
