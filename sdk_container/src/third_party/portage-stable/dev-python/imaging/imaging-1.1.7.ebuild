# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/imaging/imaging-1.1.7.ebuild,v 1.8 2010/03/07 12:51:07 ssuominen Exp $

EAPI="2"
SUPPORT_PYTHON_ABIS="1"

inherit eutils distutils

MY_P=Imaging-${PV}

DESCRIPTION="Python Imaging Library (PIL)"
HOMEPAGE="http://www.pythonware.com/products/pil/index.htm"
SRC_URI="http://www.effbot.org/downloads/${MY_P}.tar.gz"

LICENSE="as-is"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE="doc examples scanner tk X"

DEPEND="media-libs/jpeg:0
	media-libs/freetype:2
	tk? ( dev-lang/python[tk?] )
	scanner? ( media-gfx/sane-backends )
	X? ( x11-misc/xdg-utils )"
RDEPEND="${DEPEND}"

RESTRICT_PYTHON_ABIS="3*"

PYTHON_MODNAME=PIL
S="${WORKDIR}/${MY_P}"

src_prepare() {
	epatch "${FILESDIR}"/${P}-no-xv.patch
	epatch "${FILESDIR}"/${P}-sane.patch
	epatch "${FILESDIR}"/${P}-giftrans.patch
	epatch "${FILESDIR}"/${P}-missing-math.patch
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
		cd "${S}/Sane"
		distutils_src_compile
	fi
}

src_test() {
	tests() {
		PYTHONPATH="$(ls -d build-${PYTHON_ABI}/lib.*)" "$(PYTHON)" selftest.py
	}
	python_execute_function tests
}

src_install() {
	local DOCS="CHANGES CONTENTS"
	distutils_src_install

	use doc && dohtml Docs/*

	if use scanner; then
		cd "${S}/Sane"
		docinto sane
		local DOCS="CHANGES sanedoc.txt"
		distutils_src_install
		cd "${S}"
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
		doins Scripts/*
		if use scanner; then
			insinto /usr/share/doc/${PF}/examples/sane
			doins Sane/demo_*.py
		fi
	fi
}
