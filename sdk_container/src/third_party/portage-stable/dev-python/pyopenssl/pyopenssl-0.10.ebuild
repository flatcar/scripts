# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/pyopenssl/pyopenssl-0.10.ebuild,v 1.7 2010/01/16 15:10:42 armin76 Exp $

EAPI="2"
SUPPORT_PYTHON_ABIS="1"

inherit distutils eutils

MY_PN="pyOpenSSL"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Python interface to the OpenSSL library"
HOMEPAGE="http://pyopenssl.sourceforge.net/ http://pypi.python.org/pypi/pyOpenSSL"
SRC_URI="http://pypi.python.org/packages/source/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz
	mirror://sourceforge/pyopenssl/${MY_P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~x86-macos ~x64-solaris"
IUSE="doc"

RDEPEND=">=dev-libs/openssl-0.9.6g"
DEPEND="${RDEPEND}
	doc? ( >=dev-tex/latex2html-2002.2 )"
RESTRICT_PYTHON_ABIS="3.*"

S="${WORKDIR}/${MY_P}"

PYTHON_MODNAME="OpenSSL"

src_compile() {
	distutils_src_compile
	if use doc; then
		addwrite /var/cache/fonts
		# This one seems to be unnecessary with a recent tetex, but
		# according to bugs it was definitely necessary in the past,
		# so leaving it in.
		addwrite /usr/share/texmf/fonts/pk

		cd doc
		make html ps dvi
	fi
}

src_test() {
	test_package() {
		pushd test > /dev/null
		local test
		for test in test_*.py; do
			echo -e "\e[1;31mRunning ${test}...\e[0m"
			PYTHONPATH="$(ls -d ../build-${PYTHON_ABI}/lib.*)" "$(PYTHON)" "${test}" || die "${test} failed with Python ${PYTHON_ABI}"
		done
		popd > /dev/null
	}
	python_execute_function test_package
}

src_install() {
	distutils_src_install

	if use doc; then
		dohtml doc/html/*
		dodoc doc/pyOpenSSL.*
	fi

	# Install examples
	docinto examples
	dodoc examples/*
	docinto examples/simple
	dodoc examples/simple/*
}
