# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/pyopenssl/pyopenssl-0.12.ebuild,v 1.11 2011/12/22 20:24:16 floppym Exp $

EAPI="3"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="*-jython"

inherit distutils eutils

MY_PN="pyOpenSSL"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Python interface to the OpenSSL library"
HOMEPAGE="http://pyopenssl.sourceforge.net/ https://launchpad.net/pyopenssl http://pypi.python.org/pypi/pyOpenSSL"
SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris"
IUSE="doc"

RDEPEND=">=dev-libs/openssl-0.9.6g"
DEPEND="${RDEPEND}
	doc? (
		=dev-lang/python-2*
		>=dev-tex/latex2html-2002.2
	)"

S="${WORKDIR}/${MY_P}"

PYTHON_CFLAGS=("2.* + -fno-strict-aliasing")

PYTHON_MODNAME="OpenSSL"

src_prepare() {
	distutils_src_prepare
	epatch "${FILESDIR}/${PN}-0.11-openssl-1.patch"

	# Disable tests failing with OpenSSL >=1.0.0.
	sed \
		-e "s/test_dump_privatekey/_&/" \
		-e "s/test_export_without_args/_&/" \
		-e "s/test_export_without_mac/_&/" \
		-e "s/test_friendly_name/_&/" \
		-e "s/test_load_pkcs12/_&/" \
		-e "s/test_various_empty_passphrases/_&/" \
		-e "s/test_zero_len_list_for_ca/_&/" \
		-e "s/test_subject_name_hash/_&/" \
		-i OpenSSL/test/test_crypto.py
	sed -e "s/test_load_verify_directory/_&/" -i OpenSSL/test/test_ssl.py

	sed -e "s/python/&2/" -i doc/Makefile
}

src_compile() {
	distutils_src_compile

	if use doc; then
		addwrite /var/cache/fonts

		pushd doc > /dev/null
		emake -j1 html ps dvi || die "Generation of documentation failed"
		popd > /dev/null
	fi
}

src_test() {
	test_package() {
		pushd OpenSSL/test > /dev/null

		local return_status="0" test
		for test in test_*.py; do
			einfo "Running ${test}..."
			if ! PYTHONPATH="$(ls -d ../../build-${PYTHON_ABI}/lib.*)" "$(PYTHON)" "${test}"; then
				eerror "${test} failed with $(python_get_implementation) $(python_get_version)"
				return_status="1"
			fi
		done

		popd > /dev/null

		return "${return_status}"
	}
	python_execute_function test_package
}

src_install() {
	distutils_src_install

	delete_tests() {
		rm -fr "${ED}$(python_get_sitedir)/OpenSSL/test"
	}
	python_execute_function -q delete_tests

	if use doc; then
		dohtml doc/html/* || die "dohtml failed"
		dodoc doc/pyOpenSSL.* || die "dodoc failed"
	fi

	# Install examples
	insinto /usr/share/doc/${PF}/examples
	doins -r examples/* || die "doins failed"
}
