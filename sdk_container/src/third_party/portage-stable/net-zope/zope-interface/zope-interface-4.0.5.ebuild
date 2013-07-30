# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-zope/zope-interface/zope-interface-4.0.5.ebuild,v 1.2 2013/03/30 13:06:41 floppym Exp $

EAPI=5

# Tests fail with py3.1
PYTHON_COMPAT=( python{2_6,2_7,3_2,3_3} pypy{1_9,2_0} )

inherit distutils-r1 flag-o-matic

MY_PN="${PN/-/.}"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Interfaces for Python"
HOMEPAGE="http://pypi.python.org/pypi/zope.interface"
SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.zip"

LICENSE="ZPL"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

# net-zope/zope-fixers is required for building with Python 3.
DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]
	net-zope/zope-fixers[$(python_gen_usedep 'python3*')]"
RDEPEND=""

S="${WORKDIR}/${MY_P}"

python_compile() {
	if [[ ${EPYTHON} != python3* ]]; then
		local CFLAGS CXXFLAGS
		append-flags -fno-strict-aliasing
	fi

	distutils-r1_python_compile
}

python_test() {
	esetup.py test
}
