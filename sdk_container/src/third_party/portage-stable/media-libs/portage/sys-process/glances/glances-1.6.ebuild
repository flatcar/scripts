# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/glances/glances-1.6.ebuild,v 1.2 2013/02/02 18:07:40 xarthisius Exp $

EAPI=5
PYTHON_COMPAT=( python{2_6,2_7} )

inherit distutils-r1

DESCRIPTION="CLI curses based monitoring tool"
HOMEPAGE="https://github.com/nicolargo/glances/blob/master/README.md
http://pypi.python.org/pypi/Glances"
SRC_URI="https://github.com/nicolargo/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
RDEPEND="${DEPEND}
	>=dev-python/psutil-0.4.1"

python_prepare_all() {
	sed -e "s:share/doc/glances:share/doc/${PF}:g" \
		-e "/COPYING/d" \
		-e "/etc\/glances/d" \
		-i setup.py || die
	distutils-r1_python_prepare_all
}

python_install_all() {
	insinto /etc/${PN}
	doins ${PN}/conf/${PN}.conf
	distutils-r1_python_install_all
}

pkg_postinst() {
	if [[ -z ${REPLACING_VERSIONS} ]]; then
		elog "${PN} can gain additional functionality with following packages:"
		elog "   dev-python/jinja - export statistics to HTML"
	fi
}
