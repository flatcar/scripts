# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-cpp/gflags/Attic/gflags-1.2.ebuild,v 1.3 2011/02/12 21:54:15 nelchael dead $

EAPI="3"
PYTHON_DEPEND="python? 2"
SUPPORT_PYTHON_ABIS="1"

inherit distutils

DESCRIPTION="Google's C++ argument parsing library with python extensions."
HOMEPAGE="http://code.google.com/p/google-gflags/"
SRC_URI="http://google-gflags.googlecode.com/files/${P}.tar.gz"
LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
IUSE="python"

DEPEND=""
RDEPEND=""
RESTRICT_PYTHON_ABIS="3.*"

PYTHON_MODNAME="gflags.py"

src_compile() {
	default

	if use python; then
		cd python
		distutils_src_compile
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"

	rm -rf "${D}"/usr/share/doc/*
	AUTHORS ChangeLog NEWS README
	dohtml doc/*

	if use python; then
		cd python
		distutils_src_install
	fi
}

pkg_postinst() {
	if use python; then
		distutils_pkg_postinst
	fi
}

pkg_postrm() {
	if use python; then
		distutils_pkg_postrm
	fi
}
