# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/cherrypy/cherrypy-2.3.0.ebuild,v 1.4 2010/11/14 21:05:42 arfrever Exp $

EAPI="3"
PYTHON_DEPEND="2"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.*"

inherit distutils

MY_P="CherryPy-${PV}"

DESCRIPTION="CherryPy is a pythonic, object-oriented HTTP framework"
HOMEPAGE="http://www.cherrypy.org/ http://pypi.python.org/pypi/CherryPy"
SRC_URI="http://download.cherrypy.org/${PN}/${PV}/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc test"

DEPEND="dev-python/setuptools
	test? ( >=dev-python/webtest-1.0 )"
RDEPEND=""

S="${WORKDIR}/${MY_P}"

src_prepare() {
	# Remove test_cache_filter, only works outside of portage
	sed -i \
		-e '/raw_input/d' \
		-e "/'test_cache_filter',/d" \
		cherrypy/test/test.py || die "sed failed"

	sed -i \
		-e 's/"cherrypy.tutorial",//' \
		-e "/('cherrypy\/tutorial',/, /),/d" \
		-e 's/distutils.core/setuptools/' \
		setup.py || die "sed failed"
}

src_test() {
	testing() {
		PYTHONPATH="build-${PYTHON_ABI}/lib" "$(PYTHON)" cherrypy/test/test.py
	}
	python_execute_function testing
}

src_install() {
	distutils_src_install

	if use doc; then
		insinto /usr/share/doc/${PF}
		doins -r cherrypy/tutorial
	fi
}
