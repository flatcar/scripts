# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/pyxdg/pyxdg-0.25.ebuild,v 1.14 2013/05/14 22:45:40 eva Exp $

EAPI=5

# py3.3 removed due to nosetests
PYTHON_COMPAT=( python{2_6,2_7,3_1,3_2,3_3} pypy{1_8,1_9} )
inherit distutils-r1

DESCRIPTION="A Python module to deal with freedesktop.org specifications"
HOMEPAGE="http://freedesktop.org/wiki/Software/pyxdg http://cgit.freedesktop.org/xdg/pyxdg/"
SRC_URI="http://people.freedesktop.org/~takluyver/${P}.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd"
IUSE="test"

DEPEND="test? ( dev-python/nose[${PYTHON_USEDEP}]
	x11-themes/hicolor-icon-theme )"

DOCS=( AUTHORS ChangeLog README TODO )

python_test() {
	nosetests || die
}
