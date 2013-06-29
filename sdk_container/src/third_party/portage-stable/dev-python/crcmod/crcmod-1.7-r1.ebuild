# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/crcmod/crcmod-1.7-r1.ebuild,v 1.2 2012/02/10 04:08:57 patrick Exp $

# For the 2.x versions of Python, these versions have been tested: 2.4 2.5 2.6 2.7
# For the 3.x versions of Python, these versions have been tested: 3.1

# Python 3.2 seems to work also; sbriesen 2011-10-10

EAPI=3
PYTHON_DEPEND="2:2.5:2.7 3:3.1:3.2"
SUPPORT_PYTHON_ABIS="1"
#RESTRICT_PYTHON_ABIS="3.2"

inherit distutils

DESCRIPTION="Python CRC Generator module"
HOMEPAGE="http://crcmod.sourceforge.net/"
SRC_URI="mirror://sourceforge/crcmod/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DOCS="changelog test/examples.py"
