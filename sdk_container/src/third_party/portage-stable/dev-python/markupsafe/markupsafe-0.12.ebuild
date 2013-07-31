# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/markupsafe/markupsafe-0.12.ebuild,v 1.11 2013/05/28 07:44:44 idella4 Exp $

EAPI="3"
SUPPORT_PYTHON_ABIS="1"
DISTUTILS_SRC_TEST="setup.py"
RESTRICT_PYTHON_ABIS="2.7-pypy-*"

inherit distutils

MY_PN="MarkupSafe"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Implements a XML/HTML/XHTML Markup safe string for Python"
HOMEPAGE="http://pypi.python.org/pypi/MarkupSafe"
SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-linux ~x86-linux ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris"
IUSE=""

DEPEND="dev-python/setuptools"
RDEPEND=""

S="${WORKDIR}/${MY_P}"

set_global_options() {
	if [[ "$(python_get_implementation)" != "Jython" ]]; then
		DISTUTILS_GLOBAL_OPTIONS=("--with-speedups")
	else
		DISTUTILS_GLOBAL_OPTIONS=()
	fi
}

distutils_src_compile_pre_hook() {
	set_global_options
}

distutils_src_test_pre_hook() {
	set_global_options
}

distutils_src_install_pre_hook() {
	set_global_options
}

src_install() {
	distutils_src_install
	python_clean_installation_image
}
