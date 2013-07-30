# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/decorator/decorator-3.4.0-r1.ebuild,v 1.3 2013/06/14 05:16:16 idella4 Exp $

EAPI=5
PYTHON_COMPAT=( python{2_5,2_6,2_7,3_1,3_2,3_3} )

inherit distutils-r1

DESCRIPTION="Simplifies the usage of decorators for the average programmer"
HOMEPAGE="http://pypi.python.org/pypi/decorator http://code.google.com/p/micheles/"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~x86-linux ~x64-macos"
IUSE=""

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
RDEPEND=""

PATCHES=(
	"${FILESDIR}"/${P}-test-failure-exit.patch
)

python_test() {
	local t=documentation.py
	[[ ${EPYTHON} == python3* ]] && t=documentation3.py

	"${PYTHON}" ${t} || die "Tests fail with ${EPYTHON}"
}
