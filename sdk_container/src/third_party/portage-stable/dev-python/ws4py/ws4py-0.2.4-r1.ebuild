# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/ws4py/ws4py-0.2.4-r1.ebuild,v 1.2 2013/07/19 07:56:00 mgorny Exp $

# We could depend on dev-python/cherrypy when USE=server, but
# that is an optional component ...
# Same for www-servers/tornado and USE=client ...

EAPI="5"
PYTHON_COMPAT=( python2_{6,7} )
PYTHON_REQ_USE="threads?"

inherit distutils-r1
if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="git://github.com/Lawouach/WebSocket-for-Python.git"
	inherit git-2
else
	inherit vcs-snapshot
	SRC_URI="https://github.com/Lawouach/WebSocket-for-Python/tarball/v${PV} -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~x86"
fi

DESCRIPTION="WebSocket support for Python"
HOMEPAGE="https://github.com/Lawouach/WebSocket-for-Python"

LICENSE="BSD"
SLOT="0"
IUSE="+client +server test +threads"

RDEPEND=""
DEPEND="test? (
		${RDEPEND}
		dev-python/unittest2[${PYTHON_USEDEP}]
		>=dev-python/cherrypy-3.2.0[${PYTHON_USEDEP}]
		dev-python/gevent[${PYTHON_USEDEP}]
	)"

PATCHES=( "${FILESDIR}"/${PN}-0.2-cherrypy_test.patch )

python_test() {
	esetup.py test || die
}

src_install() {
	distutils-r1_src_install
	use client || rm -rf "${ED}$(python_get_sitedir)"/ws4py/client
	use server || rm -rf "${ED}$(python_get_sitedir)"/ws4py/server
}
