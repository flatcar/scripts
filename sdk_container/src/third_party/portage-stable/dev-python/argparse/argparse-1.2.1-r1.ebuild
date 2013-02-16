# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/argparse/argparse-1.2.1-r1.ebuild,v 1.15 2013/01/01 19:01:38 armin76 Exp $

EAPI=5
PYTHON_COMPAT_REAL=(
	# actual targets
	python{2_5,2_6,3_1}
)
PYTHON_COMPAT=(
	${PYTHON_COMPAT_REAL[@]}
	# these versions provide built-in argparse
	# but we still list them to warn user to migrate
	python{2_7,3_2}
)

inherit distutils-r1

DESCRIPTION="An easy, declarative interface for creating command line tools"
HOMEPAGE="http://code.google.com/p/argparse/ http://pypi.python.org/pypi/argparse"
SRC_URI="http://argparse.googlecode.com/files/${P}.tar.gz"

LICENSE="PSF-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x86-solaris"
IUSE=""

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"

pkg_pretend() {
	local x
	for x in ${PYTHON_COMPAT_REAL[@]}; do
		if use python_targets_${x}; then
			return
		fi
	done

	ewarn 'You have installed this version of argparse only for Python'
	ewarn 'implementations which provide the argparse module already.'
	ewarn 'Most likely, this means that something in your system depends on'
	ewarn 'dev-python/argparse instead of virtual/python-argparse.'
	ewarn
	ewarn 'Please try running the following command or an equivalent one:'
	ewarn
	ewarn '	emerge --verbose --depclean dev-python/argparse'
	ewarn
	ewarn 'If your package manager refuses to uninstall the package due to'
	ewarn 'unsatisfied dependencies, please first try re-installing the listed'
	ewarn 'packages and running --depclean again. If that does not help, please'
	ewarn 'report a bug against the package, requesting its maintainer to fix'
	ewarn 'the dependency on argparse to use virtual/argparse.'
}

python_test() {
	COLUMNS=80 PYTHONPATH="${BUILD_DIR}/lib" \
		"${PYTHON}" test/test_argparse.py
}
