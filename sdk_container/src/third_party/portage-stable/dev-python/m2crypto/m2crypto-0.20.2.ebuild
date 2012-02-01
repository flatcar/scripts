# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/m2crypto/m2crypto-0.20.2.ebuild,v 1.12 2010/02/14 18:00:53 arfrever Exp $

EAPI="2"
PYTHON_DEPEND="2"
SUPPORT_PYTHON_ABIS="1"

inherit distutils eutils multilib portability

MY_PN="M2Crypto"

DESCRIPTION="A python wrapper for the OpenSSL crypto library"
HOMEPAGE="http://chandlerproject.org/bin/view/Projects/MeTooCrypto http://pypi.python.org/pypi/M2Crypto"
SRC_URI="http://pypi.python.org/packages/source/${MY_PN:0:1}/${MY_PN}/${MY_PN}-${PV}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE="doc"

RDEPEND=">=dev-libs/openssl-0.9.8"
DEPEND="${RDEPEND}
	>=dev-lang/swig-1.3.25
	doc? ( dev-python/epydoc )
	dev-python/setuptools"
RESTRICT_PYTHON_ABIS="3.*"

PYTHON_MODNAME="${MY_PN}"

S="${WORKDIR}/${MY_PN}-${PV}"

DOCS="CHANGES"

src_test() {
	testing() {
		PYTHONPATH="$(ls -d build-${PYTHON_ABI}/lib*)" "$(PYTHON)" setup.py build -b "build-${PYTHON_ABI}" test
	}
	python_execute_function testing
}

src_install() {
	[[ -z ${ED} ]] && local ED=${D}
	distutils_src_install

	if use doc; then
		cd "${S}/demo"
		treecopy . "${ED}/usr/share/doc/${PF}/example"

		einfo "Generating API documentation..."
		cd "${S}/doc"
		PYTHONPATH="${ED}$(python_get_sitedir -f)" epydoc --html --output=api --name=M2Crypto M2Crypto
	fi
	dohtml -r *
}
