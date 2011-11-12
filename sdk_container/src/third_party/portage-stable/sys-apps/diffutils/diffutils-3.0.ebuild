# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/diffutils/diffutils-3.0.ebuild,v 1.7 2011/05/29 11:25:20 armin76 Exp $

inherit flag-o-matic

DESCRIPTION="Tools to make diffs and compare files"
HOMEPAGE="http://www.gnu.org/software/diffutils/"
SRC_URI="ftp://alpha.gnu.org/gnu/diffutils/${P}.tar.gz
	mirror://gnu/diffutils/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="nls static"

RDEPEND=""
DEPEND="nls? ( sys-devel/gettext )"

src_compile() {
	use static && append-ldflags -static

	# Disable automagic dependency over libsigsegv; see bug #312351.
	export ac_cv_libsigsegv=no

	econf \
		--with-packager="Gentoo" \
		--with-packager-version="${PVR}" \
		--with-packager-bug-reports="http://bugs.gentoo.org/" \
		$(use_enable nls) \
		|| die
	emake || die
}

src_test() {
	# explicitly allow parallel testing
	emake check || die
}

src_install() {
	emake install DESTDIR="${D}" || die
	dodoc AUTHORS ChangeLog NEWS README THANKS TODO || die
}
