# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/pycairo/pycairo-1.8.10.ebuild,v 1.16 2012/06/02 11:59:24 marienz Exp $

EAPI="3"
PYTHON_DEPEND="2:2.6"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="2.4 2.5 3.* *-pypy-*"
DISTUTILS_SRC_TEST="py.test"

inherit eutils distutils flag-o-matic multilib

DESCRIPTION="Python wrapper for cairo vector graphics library"
HOMEPAGE="http://cairographics.org/pycairo/ http://pypi.python.org/pypi/pycairo"
SRC_URI="http://cairographics.org/releases/py2cairo-${PV}.tar.gz"

LICENSE="|| ( LGPL-2.1 MPL-1.1 )"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="doc examples svg"

RDEPEND=">=x11-libs/cairo-1.8.10[svg?]"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( >=dev-python/sphinx-0.6 )"

DOCS="AUTHORS NEWS README"
PYTHON_MODNAME="cairo"

src_prepare() {
	distutils_src_prepare
	epatch "${FILESDIR}/${P}-pkgconfig_dir.patch"
	epatch "${FILESDIR}/${PN}-1.8.8-svg_check.patch"
}

src_configure() {
	if ! use svg; then
		export PYCAIRO_DISABLE_SVG="1"
	fi
}

distutils_src_compile_post_hook() {
	cp src/__init__.py "$(ls -d build-${PYTHON_ABI}/lib.*/cairo)" || die "Copying of src/__init__.py failed"
}

src_compile() {
	append-flags -fno-strict-aliasing
	distutils_src_compile

	if use doc; then
		einfo "Generation of documentation"
		pushd doc > /dev/null
		sphinx-build -b html -d .build/doctrees . .build/html || die "Generation of documentation failed"
		popd > /dev/null
	fi
}

src_test() {
	python_execute_py.test -P '$(ls -d build-${PYTHON_ABI}/lib.*):../../$(ls -d build-${PYTHON_ABI}/lib.*)'
}

src_install() {
	PKGCONFIG_DIR="${EPREFIX}/usr/$(get_libdir)/pkgconfig" distutils_src_install

	if use doc; then
		dohtml -r doc/.build/html/ || die "dohtml -r doc/.build/html/ failed"
	fi

	if use examples; then
		# Delete files created by tests.
		find examples/cairo_snippets/snippets -maxdepth 1 -name "*.png" | xargs rm -f

		insinto /usr/share/doc/${PF}/examples
		doins -r examples/*
		rm "${ED}"usr/share/doc/${PF}/examples/Makefile*
	fi
}
