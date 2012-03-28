# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/imaging/imaging-1.1.7-r1.ebuild,v 1.10 2012/04/17 21:57:44 ranger Exp $

EAPI="3"
PYTHON_DEPEND="2"
PYTHON_USE_WITH="tk"
PYTHON_USE_WITH_OPT="tk"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.* *-jython 2.7-pypy-*"

inherit eutils multilib distutils

MY_P=Imaging-${PV}

DESCRIPTION="Python Imaging Library (PIL)"
HOMEPAGE="http://www.pythonware.com/products/pil/index.htm"
SRC_URI="http://www.effbot.org/downloads/${MY_P}.tar.gz"

LICENSE="as-is"
SLOT="0"
KEYWORDS="~alpha amd64 arm hppa ~ia64 ppc ppc64 ~sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x86-solaris"
IUSE="doc examples lcms scanner tk X"

DEPEND="virtual/jpeg
	media-libs/freetype:2
	lcms? ( media-libs/lcms:0 )
	scanner? ( media-gfx/sane-backends )
	X? ( x11-misc/xdg-utils )"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${MY_P}"

DOCS="CHANGES CONTENTS"

pkg_setup() {
	PYTHON_MODNAME="PIL $(use scanner && echo sane.py)"
	python_pkg_setup
}

src_prepare() {
	distutils_src_prepare

	epatch "${FILESDIR}/${P}-no-xv.patch"
	epatch "${FILESDIR}/${P}-sane.patch"
	epatch "${FILESDIR}/${P}-giftrans.patch"
	epatch "${FILESDIR}/${P}-missing-math.patch"
	if ! use lcms; then
		epatch "${FILESDIR}/${P}-nolcms.patch"
	fi

	# Add shebang.
	sed -e "1i#!/usr/bin/python" -i Scripts/pilfont.py \
		|| die "sed	failed adding shebang"

	sed -i \
		-e "s:/usr/lib\":/usr/$(get_libdir)\":" \
		-e "s:\"lib\":\"$(get_libdir)\":g" \
		setup.py || die "sed failed"

	if ! use tk; then
		# Make the test always fail
		sed -i \
			-e 's/import _tkinter/raise ImportError/' \
			setup.py || die "sed failed"
	fi
}

src_compile() {
	distutils_src_compile

	if use scanner; then
		pushd Sane > /dev/null
		distutils_src_compile
		popd > /dev/null
	fi
}

src_test() {
	tests() {
		PYTHONPATH="$(ls -d build-${PYTHON_ABI}/lib.*)" "$(PYTHON)" selftest.py
	}
	python_execute_function tests
}

src_install() {
	distutils_src_install

	if use doc; then
		dohtml Docs/* || die "dohtml failed"
	fi

	if use scanner; then
		pushd Sane > /dev/null
		docinto sane
		DOCS="CHANGES sanedoc.txt" distutils_src_install
		popd > /dev/null
	fi

	# Install headers required by media-gfx/sketch.
	install_headers() {
		insinto "$(python_get_includedir)"
		doins libImaging/Imaging.h
		doins libImaging/ImPlatform.h
	}
	python_execute_function install_headers

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins Scripts/* || die "doins failed"

		if use scanner; then
			insinto /usr/share/doc/${PF}/examples/sane
			doins Sane/demo_*.py || die "doins failed"
		fi
	fi
}
