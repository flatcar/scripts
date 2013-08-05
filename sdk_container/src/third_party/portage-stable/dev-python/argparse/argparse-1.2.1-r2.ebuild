# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/argparse/argparse-1.2.1-r2.ebuild,v 1.13 2013/04/12 17:20:01 ago Exp $

EAPI=5
# Other implementations ship argparse.
PYTHON_COMPAT=( python{2_5,2_6,3_1} )

inherit distutils-r1

DESCRIPTION="An easy, declarative interface for creating command line tools"
HOMEPAGE="http://code.google.com/p/argparse/ http://pypi.python.org/pypi/argparse"
SRC_URI="http://argparse.googlecode.com/files/${P}.tar.gz"

LICENSE="PSF-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc ~x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x86-solaris"
IUSE=""

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"

python_test() {
	COLUMNS=80 PYTHONPATH="${BUILD_DIR}/lib" \
		"${PYTHON}" test/test_argparse.py
}
