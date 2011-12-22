# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/gperf/gperf-3.0.4.ebuild,v 1.13 2011/05/03 06:58:29 grobian Exp $

EAPI="3"

DESCRIPTION="A perfect hash function generator"
HOMEPAGE="http://www.gnu.org/software/gperf/gperf.html"
SRC_URI="mirror://gnu/gperf/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

src_install() {
	emake DESTDIR="${D}" htmldir="${EPREFIX}"/usr/share/doc/${PF}/html install || die
	dodoc AUTHORS ChangeLog NEWS README
}
