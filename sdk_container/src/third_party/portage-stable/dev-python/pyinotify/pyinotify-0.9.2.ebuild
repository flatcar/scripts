# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/pyinotify/pyinotify-0.9.2.ebuild,v 1.8 2012/02/07 23:09:38 floppym Exp $

EAPI="3"
PYTHON_DEPEND="*:2.5"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="2.4 *-jython"

inherit distutils

DESCRIPTION="Python module used for monitoring filesystems events"
HOMEPAGE="http://trac.dbzteam.org/pyinotify http://pypi.python.org/pypi/pyinotify"
SRC_URI="http://seb.dbzteam.org/pub/pyinotify/releases/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ppc x86 ~amd64-linux ~x86-linux"
IUSE="examples"

DEPEND="dev-python/setuptools"
RDEPEND=""

S="${WORKDIR}/${PN}"

PYTHON_MODNAME="pyinotify.py"

src_install() {
	distutils_src_install

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins python2/examples/* || die "Installation of examples failed"
	fi
}
