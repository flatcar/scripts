# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libmaa/libmaa-1.3.0.ebuild,v 1.7 2012/03/18 19:50:20 armin76 Exp $

EAPI="4"

DESCRIPTION="Library with low-level data structures which are helpful for writing compilers"
HOMEPAGE="http://www.dict.org/"
SRC_URI="mirror://sourceforge/dict/${P}.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="alpha amd64 ~hppa ia64 ~mips ppc ppc64 sparc x86 ~amd64-linux ~ia64-linux ~x86-linux"
IUSE=""

src_install() {
	emake DESTDIR="${D}" install
	dodoc ChangeLog NEWS README doc/libmaa.600dpi.ps
}
