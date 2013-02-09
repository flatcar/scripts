# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/python-unittest2/python-unittest2-1.ebuild,v 1.3 2013/01/28 13:37:40 aballier Exp $

EAPI=5
PYTHON_COMPAT=( python{2_5,2_6,2_7,3_1,3_2,3_3} pypy{1_9,2_0} )
inherit python-r1

DESCRIPTION="A virtual for packages needing unittest2 in Python 2.5, 2.6, 3.1"
HOMEPAGE=""
SRC_URI=""

KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
LICENSE=""
SLOT="0"
IUSE=""

RDEPEND="dev-python/unittest2:0"
