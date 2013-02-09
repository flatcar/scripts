# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libksba/libksba-1.2.0.ebuild,v 1.10 2012/05/09 15:18:25 aballier Exp $

EAPI="3"

DESCRIPTION="X.509 and CMS (PKCS#7) library"
HOMEPAGE="http://www.gnupg.org/related_software/libksba"
#SRC_URI="ftp://ftp.gnupg.org/gcrypt/${PN}/${P}.tar.bz2"
SRC_URI="mirror://gnupg/libksba/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="static-libs"

DEPEND=">=dev-libs/libgpg-error-1.8"
RDEPEND="${DEPEND}"

src_configure() {
	econf $(use_enable static-libs static)
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	find "${ED}" -name "*.la" -print0 | xargs -0 rm -f
	dodoc AUTHORS ChangeLog NEWS README THANKS TODO VERSION || die "dodoc failed"
}
