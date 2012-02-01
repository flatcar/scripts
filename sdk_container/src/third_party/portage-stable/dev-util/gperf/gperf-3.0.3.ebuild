# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/gperf/gperf-3.0.3.ebuild,v 1.8 2008/12/07 12:13:50 vapier Exp $

DESCRIPTION="A perfect hash function generator"
HOMEPAGE="http://www.gnu.org/software/gperf/gperf.html"
SRC_URI="mirror://gnu/gperf/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE=""

src_install() {
	emake DESTDIR="${D}" htmldir=/usr/share/doc/${PF}/html install || die
	dodoc AUTHORS ChangeLog NEWS README
}
