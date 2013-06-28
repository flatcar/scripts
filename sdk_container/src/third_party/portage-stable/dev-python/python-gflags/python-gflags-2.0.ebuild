# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/python-gflags/python-gflags-2.0.ebuild,v 1.5 2012/12/17 19:59:53 mgorny Exp $

EAPI="5"

PYTHON_COMPAT=( python{2_5,2_6,2_7} pypy{1_8,1_9} )

inherit distutils-r1

DESCRIPTION="Google's Python argument parsing library"
HOMEPAGE="http://code.google.com/p/python-gflags/"
SRC_URI="http://python-gflags.googlecode.com/files/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
RDEPEND=""

PATCHES=(
	# The scripts are installed as 'data' rather than scripts.
	# http://code.google.com/p/python-gflags/issues/detail?id=12
	"${FILESDIR}"/${P}-scripts-install.patch

	# Tests try to write to /tmp (sandbox).
	# http://code.google.com/p/python-gflags/issues/detail?id=13
	"${FILESDIR}"/${P}-tests-respect-tmpdir.patch
)

python_test() {
	local t

	cd tests || die
	for t in *.py; do
		# (it's ok to run the gflags_googletest.py too)
		"${PYTHON}" "${t}" || die "Tests fail with ${EPYTHON}"
	done
}
