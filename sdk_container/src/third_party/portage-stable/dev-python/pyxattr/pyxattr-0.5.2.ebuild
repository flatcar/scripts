# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/pyxattr/pyxattr-0.5.2.ebuild,v 1.16 2014/03/31 21:03:55 mgorny Exp $

EAPI=5
PYTHON_COMPAT=( python{2_6,2_7,3_2,3_3} pypy pypy2_0 )

inherit distutils-r1 eutils

DESCRIPTION="Python interface to xattr"
HOMEPAGE="http://pyxattr.k1024.org/"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz
	http://pyxattr.k1024.org/downloads/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-linux ~arm-linux ~x86-linux"
IUSE="test"

RDEPEND="sys-apps/attr"
DEPEND="${RDEPEND}
	dev-python/setuptools[${PYTHON_USEDEP}]
	test? ( dev-python/nose[${PYTHON_USEDEP}] )"

python_prepare_all() {
	sed -i -e 's:, "-Werror"::' setup.py || die

	distutils-r1_python_prepare_all
}

src_test() {
	# Perform the tests in /var/tmp; that location is more likely
	# to have xattr support than /tmp which is often tmpfs.
	export TESTDIR=/var/tmp

	einfo 'Please note that the tests fail if xattrs are not supported'
	einfo 'by the filesystem used for /var/tmp.'
	distutils-r1_src_test
}

python_test() {
	nosetests || die "Tests fail with ${EPYTHON}"
}
