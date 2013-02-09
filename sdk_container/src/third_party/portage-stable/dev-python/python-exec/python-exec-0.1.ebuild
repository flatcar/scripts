# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/python-exec/python-exec-0.1.ebuild,v 1.10 2012/12/17 19:43:44 mgorny Exp $

EAPI=5

inherit autotools-utils python-r1

DESCRIPTION="Python script wrapper"
HOMEPAGE="https://bitbucket.org/mgorny/python-exec/"
SRC_URI="mirror://bitbucket/mgorny/${PN}/downloads/${P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

append_impl() {
	pyimpls+="${EPYTHON} "
}

src_configure() {
	local pyimpls
	python_foreach_impl append_impl

	local myeconfargs=(
		--with-python-impls="${pyimpls}"
	)

	autotools-utils_src_configure
}
