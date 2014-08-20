# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/markdown/markdown-2.1.0.ebuild,v 1.2 2012/10/06 23:50:48 floppym Exp $

EAPI="3"
PYTHON_DEPEND="2"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.*"

inherit distutils

MY_PN="Markdown"
MY_P=${MY_PN}-${PV}

DESCRIPTION="Python implementation of the markdown markup language"
HOMEPAGE="http://www.freewisdom.org/projects/python-markdown http://pypi.python.org/pypi/Markdown"
SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"

LICENSE="|| ( BSD GPL-2 )"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~ia64 ~ppc ~sparc ~x86 ~ppc-macos ~x86-macos"
IUSE="doc test pygments"

DEPEND="test? ( dev-python/nose )"
RDEPEND="pygments? ( dev-python/pygments )"

S="${WORKDIR}/${MY_P}"

src_install() {
	distutils_src_install

	if use doc; then
		dodoc docs/[!extensions]*
		docinto extensions
		dodoc docs/extensions/*
	fi
}

src_test() {
	testing() {
		"$(PYTHON)" run-tests.py
	}
	python_execute_function testing
}
