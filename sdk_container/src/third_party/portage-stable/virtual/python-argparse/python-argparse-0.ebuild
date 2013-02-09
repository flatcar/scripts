# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/python-argparse/python-argparse-0.ebuild,v 1.3 2013/01/06 01:23:28 floppym Exp $

EAPI=5
PYTHON_COMPAT=( python{2_5,2_6,2_7,3_1,3_2,3_3} pypy{1_8,1_9} jython2_5 )
inherit python-r1

DESCRIPTION="A virtual for the Python argparse module"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x86-solaris"
IUSE=""

setup_globals() {
	local i

	RDEPEND=
	for i in "${PYTHON_COMPAT[@]}"; do
		case "${i}" in
			python2_5|python2_6|python3_1|jython2_5)
				# Note: add USE-deps when dev-python/argparse starts
				# supporting PYTHON_TARGETS
				RDEPEND+=" python_targets_${i}? ( dev-python/argparse )"
				;;
			*)
				;;
		esac
	done
}
setup_globals
