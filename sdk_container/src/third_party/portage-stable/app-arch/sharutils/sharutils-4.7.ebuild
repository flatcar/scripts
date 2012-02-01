# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-arch/sharutils/sharutils-4.7.ebuild,v 1.10 2010/02/24 15:48:44 jer Exp $

inherit eutils

MY_P="${P/_/-}"
DESCRIPTION="Tools to deal with shar archives"
HOMEPAGE="http://www.gnu.org/software/sharutils/"
SRC_URI="mirror://gnu/${PN}/REL-${PV}/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="nls"

DEPEND="sys-apps/texinfo
	nls? ( >=sys-devel/gettext-0.10.35 )"

S=${WORKDIR}/${MY_P}

src_unpack() {
	unpack ${A}
	cd "${S}"

	epatch "${FILESDIR}"/${PN}-4.6.3-interix.patch
}

src_compile() {
	strip-linguas -u po
	econf $(use_enable nls)
	emake || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog NEWS README THANKS TODO
}
