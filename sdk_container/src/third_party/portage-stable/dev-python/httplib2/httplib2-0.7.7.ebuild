# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/httplib2/httplib2-0.7.7.ebuild,v 1.2 2013/09/05 18:46:31 mgorny Exp $

EAPI="5"
PYTHON_COMPAT=( python{2_6,2_7,3_2,3_3} )

inherit distutils-r1

DESCRIPTION="A comprehensive HTTP client library"
HOMEPAGE="http://code.google.com/p/httplib2/ http://pypi.python.org/pypi/httplib2"
SRC_URI="http://httplib2.googlecode.com/files/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-linux ~x64-macos ~x86-linux"
IUSE=""

# tests connect to random remote sites
RESTRICT="test"

python_test() {
	if [[ ${EPYTHON} == python2.* ]] ; then
		cd python2
	else
		cd python3
	fi

	"${PYTHON}" httplib2test.py || die
}
