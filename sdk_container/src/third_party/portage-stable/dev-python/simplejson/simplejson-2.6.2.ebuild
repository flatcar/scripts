# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/simplejson/simplejson-2.6.2.ebuild,v 1.6 2012/11/20 20:56:30 ago Exp $

EAPI="4"
PYTHON_DEPEND="2"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.*"

inherit distutils

DESCRIPTION="Simple, fast, extensible JSON encoder/decoder for Python"
HOMEPAGE="http://undefined.org/python/#simplejson http://pypi.python.org/pypi/simplejson"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 arm ppc ~sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
IUSE=""

PYTHON_CFLAGS=("2.* + -fno-strict-aliasing")

src_test() {
	testing() {
		if [[ "$(python_get_implementation)" != "Jython" ]]; then
			ln -fs ../$(ls -d build-${PYTHON_ABI}/lib*)/simplejson/_speedups.so simplejson/_speedups.so || return 1
		fi
		PYTHONPATH="build-${PYTHON_ABI}/lib" "$(PYTHON)" simplejson/tests/__init__.py
	}
	python_execute_function testing
}

src_install() {
	distutils_src_install

	delete_tests() {
		rm -fr "${ED}$(python_get_sitedir)/simplejson/tests"
	}
	python_execute_function -q delete_tests
}
