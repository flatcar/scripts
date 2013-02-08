# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/setuptools/setuptools-0.6.30-r1.ebuild,v 1.14 2013/01/01 18:59:21 armin76 Exp $

EAPI="5"
PYTHON_COMPAT=( python{2_5,2_6,2_7,3_1,3_2} )

inherit distutils-r1 eutils

MY_PN="distribute"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Distribute (fork of Setuptools) is a collection of extensions to Distutils"
HOMEPAGE="http://pypi.python.org/pypi/distribute"
SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"

LICENSE="PSF-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

S="${WORKDIR}/${MY_P}"

# The build system modifies sources.
DISTUTILS_IN_SOURCE_BUILD=1

DOCS=(
	README.txt docs/{easy_install.txt,pkg_resources.txt,setuptools.txt}
)

python_prepare_all() {
	local PATCHES=(
		"${FILESDIR}/${PN}-0.6_rc7-noexe.patch"
		"${FILESDIR}/distribute-0.6.16-fix_deprecation_warnings.patch"
	)

	# Disable tests requiring network connection.
	rm -f setuptools/tests/test_packageindex.py

	distutils-r1_python_prepare_all
}

python_test() {
	# they fail with everything but py2.6 & 2.7
	esetup.py test
}

python_install() {
	DISTRIBUTE_DISABLE_VERSIONED_EASY_INSTALL_SCRIPT="1" \
		DONT_PATCH_SETUPTOOLS="1" \
		distutils-r1_python_install
}
