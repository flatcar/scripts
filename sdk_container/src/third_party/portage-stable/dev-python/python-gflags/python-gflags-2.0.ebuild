# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/python-gflags/python-gflags-2.0.ebuild,v 1.12 2014/03/31 20:42:14 mgorny Exp $

EAPI="5"

PYTHON_COMPAT=( python{2_6,2_7} pypy pypy2_0 )

inherit distutils-r1

DESCRIPTION="Google's Python argument parsing library"
HOMEPAGE="http://code.google.com/p/python-gflags/"
SRC_URI="http://python-gflags.googlecode.com/files/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE=""

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
RDEPEND=""

PATCHES=(
	"${FILESDIR}"/${P}-scripts-install.patch
	"${FILESDIR}"/${P}-tests-respect-tmpdir.patch
	"${FILESDIR}"/${P}-skip-test-as-root.patch #475134
	"${FILESDIR}"/${P}-tests-python-2.7.patch #447482
)

python_test() {
	# http://code.google.com/p/python-gflags/issues/detail?id=15&thanks=15&ts=1372948007
	local t
	cd tests || die
	for t in *.py; do
		# (it's ok to run the gflags_googletest.py too)
		"${PYTHON}" "${t}" || die "Tests fail with ${EPYTHON}"
	done
}
