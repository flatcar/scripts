# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/cherrypy/cherrypy-3.2.0.ebuild,v 1.6 2011/04/23 18:16:03 armin76 Exp $

EAPI="3"
SUPPORT_PYTHON_ABIS="1"
DISTUTILS_SRC_TEST="nosetests"

inherit distutils

MY_P="CherryPy-${PV}"

DESCRIPTION="CherryPy is a pythonic, object-oriented HTTP framework"
HOMEPAGE="http://www.cherrypy.org/ http://pypi.python.org/pypi/CherryPy"
SRC_URI="http://download.cherrypy.org/${PN}/${PV}/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 ia64 ppc x86 ~amd64-linux ~x86-linux ~x86-macos"
IUSE="doc"

DEPEND="dev-python/setuptools"
RDEPEND=""

S="${WORKDIR}/${MY_P}"

src_prepare() {
	distutils_src_prepare
	sed -i \
		-e 's/"cherrypy.tutorial", //' \
		-e "/('cherrypy\/tutorial',/,/),/d" \
		setup.py || die "sed failed"
}

src_test() {
	testing() {
		PYTHONPATH="build-${PYTHON_ABI}/lib" nosetests -P -s py$(python_get_version --major)/cherrypy/test
	}
	python_execute_function testing
#	python_execute_nosetests -e -P 'build-${PYTHON_ABI}/lib' -- -P -s 'py$(python_get_version --major)/cherrypy/test'
}

src_install() {
	distutils_src_install

	delete_tests() {
		rm -fr "${ED}$(python_get_sitedir)/cherrypy/test"
	}
	python_execute_function -q delete_tests

	if use doc; then
		insinto /usr/share/doc/${PF}
		# py2/cherrypy/tutorial and py3/cherrypy/tutorial are identical.
		doins -r py3/cherrypy/tutorial || die "Installation of documentation failed"
	fi
}
