# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/ws4py/ws4py-9999.ebuild,v 1.4 2012/07/17 02:11:37 vapier Exp $

# The gevent package isn't in the tree yet, so we delete
# those implementations.
#
# We could depend on dev-python/cherrypy when USE=server, but
# that is an optional component ...
# Same for www-servers/tornado and USE=client ...

EAPI="4"
PYTHON_DEPEND="2:2.6"
DISTUTILS_SRC_TEST="setup.py"

inherit distutils eutils
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

RDEPEND="client? ( dev-lang/python[threads?] )"
DEPEND="test? (
		${RDEPEND}
		dev-python/cherrypy
		dev-python/gevent
	)"

src_install() {
	distutils_src_install
	# We don't have a gevent pkg in the tree, so punt.
	rm -rf "${ED}$(python_get_sitedir)"/ws4py/*/gevent*.py
	use client || rm -rf "${ED}$(python_get_sitedir)"/ws4py/client
	use server || rm -rf "${ED}$(python_get_sitedir)"/ws4py/server
}
