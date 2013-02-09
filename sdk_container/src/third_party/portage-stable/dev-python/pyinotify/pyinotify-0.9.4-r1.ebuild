# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/pyinotify/pyinotify-0.9.4-r1.ebuild,v 1.3 2013/01/22 19:48:35 chutzpah Exp $

EAPI=5
PYTHON_COMPAT=( python{2_5,2_6,2_7,3_1,3_2,3_3} pypy{1_8,1_9} )

inherit distutils-r1

DESCRIPTION="Python module used for monitoring filesystems events"
HOMEPAGE="http://trac.dbzteam.org/pyinotify http://pypi.python.org/pypi/pyinotify"
SRC_URI="http://seb.dbzteam.org/pub/pyinotify/releases/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86 ~amd64-linux ~x86-linux"
IUSE="examples"

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
RDEPEND=""

python_prepare() {
	local pythonver=${EPYTHON#python}
	[[ ${pythonver//./} -ge 33 ]] && epatch "${FILESDIR}"/${P}-workaround-sandbox-bug.patch
}

python_install_all() {
	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins python2/examples/* || die "Installation of examples failed"
	fi
}
