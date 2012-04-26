# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/requests/requests-0.11.1.ebuild,v 1.1 2012/03/31 15:58:43 floppym Exp $

EAPI="4"
PYTHON_DEPEND="*:2.6"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="2.4 2.5"

inherit distutils

DESCRIPTION="HTTP library for human beings"
HOMEPAGE="http://python-requests.org/ http://pypi.python.org/pypi/requests"
SRC_URI="mirror://pypi/${P:0:1}/${PN}/${P}.tar.gz"

LICENSE="ISC"
SLOT="0"
KEYWORDS="amd64 ~x86"
IUSE=""

DEPEND="dev-python/setuptools"
RDEPEND=">=dev-python/certifi-0.0.7
	>=dev-python/chardet-1.0.0"
