# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/pycairo/pycairo-1.10.0-r3.ebuild,v 1.14 2013/01/06 09:29:29 ago Exp $

EAPI="4"
PYTHON_DEPEND="2:2.6 3:3.1"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="2.5 3.0 *-jython *-pypy-*"

inherit eutils python waf-utils

PYCAIRO_PYTHON2_VERSION="${PV}"
PYCAIRO_PYTHON3_VERSION="${PV}"

DESCRIPTION="Python bindings for the cairo library"
HOMEPAGE="http://cairographics.org/pycairo/ http://pypi.python.org/pypi/pycairo"
SRC_URI="http://cairographics.org/releases/py2cairo-${PYCAIRO_PYTHON2_VERSION}.tar.bz2
	http://cairographics.org/releases/pycairo-${PYCAIRO_PYTHON3_VERSION}.tar.bz2"

# LGPL-3 for pycairo 1.10.0.
# || ( LGPL-2.1 MPL-1.1 ) for pycairo 1.8.10.
LICENSE="LGPL-3 || ( LGPL-2.1 MPL-1.1 )"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~ppc-macos ~x64-macos ~x86-macos"
IUSE="doc examples +svg test xcb"

RDEPEND=">=x11-libs/cairo-1.10.0[svg?,xcb?]
	xcb? ( x11-libs/xpyb )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	test? ( dev-python/pytest )"

PYTHON_CFLAGS=("2.* + -fno-strict-aliasing")

src_prepare() {

	pushd "${WORKDIR}/pycairo-${PYCAIRO_PYTHON3_VERSION}" > /dev/null
	rm -f src/config.h || die
	epatch "${FILESDIR}/${PN}-1.10.0-svg_check.patch"
	epatch "${FILESDIR}/${PN}-1.10.0-xpyb.patch"
	epatch "${FILESDIR}"/py2cairo-1.10.0-ppc-darwin.patch
	popd > /dev/null

	pushd "${WORKDIR}/py2cairo-${PYCAIRO_PYTHON2_VERSION}" > /dev/null
	rm -f src/config.h || die
	epatch "${FILESDIR}/py2cairo-1.10.0-svg_check.patch"
	epatch "${FILESDIR}/py2cairo-1.10.0-xpyb.patch"
	epatch "${FILESDIR}"/py2cairo-1.10.0-ppc-darwin.patch
	popd > /dev/null

	preparation() {
		if [[ "${PYTHON_ABI}" == 3.* ]]; then
			cp -r "${WORKDIR}/pycairo-${PYCAIRO_PYTHON3_VERSION}" "${WORKDIR}/${P}-${PYTHON_ABI}"
		else
			cp -r "${WORKDIR}/py2cairo-${PYCAIRO_PYTHON2_VERSION}" "${WORKDIR}/${P}-${PYTHON_ABI}"
		fi
	}
	python_execute_function preparation
}

src_configure() {
	if ! use svg; then
		export PYCAIRO_DISABLE_SVG=1
	fi

	if ! use xcb; then
		export PYCAIRO_DISABLE_XPYB=1
	fi

	# Added by grobian:
	# If WAF_BINARY is an absolute path, the configure is different and fails to
	# find Python.h due to a compiler misconfiguration.  If WAF_BINARY is just
	# ./waf or python waf, it works fine.  Hooray for reinvented buildsystems

	# floppym:
	# pycairo and py2cairo bundle different versions of waf (bug 447856)
	WAF_BINARY="./waf"
	python_execute_function -s waf-utils_src_configure --nopyc --nopyo
}

src_compile() {
	python_execute_function -s waf-utils_src_compile
}

src_test() {
	test_installation() {
		./waf install --destdir="${T}/tests/${PYTHON_ABI}"
	}
	python_execute_function -q -s test_installation

	python_execute_py.test -P '${T}/tests/${PYTHON_ABI}${EPREFIX}$(python_get_sitedir)' -s
}

src_install() {
	python_execute_function -s waf-utils_src_install

	dodoc AUTHORS NEWS README || die "dodoc failed"

	if use doc; then
		pushd doc/_build/html > /dev/null
		insinto /usr/share/doc/${PF}/html
		doins -r [a-z]* _static || die "Installation of documentation failed"
		popd > /dev/null
	fi

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins -r examples/* || die "Installation of examples failed"
	fi

	if [[ ${CHOST} == *-darwin* ]] ; then
		# fix install_names; next to waf producing dylibs (not bundles) and
		# calling them .bundle, it also has no idea what it should do to create
		# proper ones (dylibs)
		fix_darwin_install_names() {
			local x=$(python_get_sitedir)/cairo/_cairo.bundle
			install_name_tool -id "${EPREFIX}${x}" "${ED}${x}"
		}
		python_execute_function fix_darwin_install_names
	fi
}

pkg_postinst() {
	python_mod_optimize cairo
}

pkg_postrm() {
	python_mod_cleanup cairo
}
