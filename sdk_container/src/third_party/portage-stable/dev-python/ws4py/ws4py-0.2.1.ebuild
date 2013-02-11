# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/ws4py/ws4py-0.2.1.ebuild,v 1.2 2012/06/11 14:13:15 mgorny Exp $

EAPI="4"
PYTHON_DEPEND="2"

inherit distutils
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
IUSE=""
#IUSE="client server"

# The gevent package isn't in the tree yet.
#RDEPEND="client? ( >=dev-python/gevent-0.13.6 )
#	server? ( >=dev-python/gevent-0.13.6 )"
DEPEND=""

src_install() {
	distutils_src_install
	#use client || rm -rf "${ED}$(python_get_sitedir)"/ws4py/client
	#use server || rm -rf "${ED}$(python_get_sitedir)"/ws4py/server
	rm -rf "${ED}$(python_get_sitedir)"/ws4py/{client,server}
}
