# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/jsonrpclib/jsonrpclib-9999.ebuild,v 1.1 2012/04/18 14:54:21 vapier Exp $

EAPI="4"

SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.*"
inherit distutils

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="git://github.com/joshmarshall/jsonrpclib.git"
	inherit git-2
else
	SRC_URI="mirror://gentoo/${P}.tar.bz2"
	KEYWORDS="~amd64 ~arm ~x86"
fi

DESCRIPTION="python implementation of the JSON-RPC spec (1.0 and 2.0)"
HOMEPAGE="https://github.com/joshmarshall/jsonrpclib"

LICENSE="Apache-2.0"
SLOT="0"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}
	dev-python/simplejson"
