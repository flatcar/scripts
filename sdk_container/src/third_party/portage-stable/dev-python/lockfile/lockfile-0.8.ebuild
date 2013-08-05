# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/lockfile/lockfile-0.8.ebuild,v 1.4 2013/01/26 05:38:07 prometheanfire Exp $

EAPI="3"
PYTHON_DEPEND="2:2.5"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="2.4 3.*"

inherit distutils

DESCRIPTION="Platform-independent file locking module"
HOMEPAGE="http://code.google.com/p/pylockfile/ http://pypi.python.org/pypi/lockfile http://smontanaro.dyndns.org/python/"
SRC_URI="http://pylockfile.googlecode.com/files/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~x86"
IUSE="doc"

DEPEND="doc? ( dev-python/sphinx )"
RDEPEND=""

DOCS="ACKS README RELEASE-NOTES"

src_compile() {
	distutils_src_compile

	if use doc; then
		einfo "Generation of documentation"
		cd doc
		emake html || die "Generation of documentation failed"
	fi
}

src_install() {
	distutils_src_install

	if use doc; then
		cd doc/.build/html
		docinto html
		cp -R [a-z]* _static "${ED}usr/share/doc/${PF}/html" || die "Installation of documentation failed"
	fi
}
