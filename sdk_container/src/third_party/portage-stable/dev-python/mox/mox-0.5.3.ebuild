# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/mox/mox-0.5.3.ebuild,v 1.4 2010/10/05 19:49:02 maekke Exp $

EAPI=3

PYTHON_DEPEND="2"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.*"

inherit distutils

DESCRIPTION="A mock object framework for Python, loosely based on EasyMock for Java"
HOMEPAGE="http://code.google.com/p/pymox/"
SRC_URI="http://pymox.googlecode.com/files/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 ppc ~sparc x86"
IUSE=""

PYTHON_MODNAME="mox.py stubout.py"

src_test() {
	testing() {
		$(PYTHON) mox_test.py || die
	}

	python_execute_function testing
}
