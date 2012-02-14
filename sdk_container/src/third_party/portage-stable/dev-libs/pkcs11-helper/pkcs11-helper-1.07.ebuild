# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/pkcs11-helper/pkcs11-helper-1.07.ebuild,v 1.7 2009/06/09 02:23:38 jer Exp $

DESCRIPTION="PKCS#11 helper library"
HOMEPAGE="http://www.opensc-project.org/pkcs11-helper"
SRC_URI="http://www.opensc-project.org/files/${PN}/${P}.tar.bz2"

LICENSE="|| ( BSD GPL-2 )"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE="doc gnutls nss"
RESTRICT="test"

RDEPEND=">=dev-libs/openssl-0.9.7
	gnutls? ( >=net-libs/gnutls-1.4.4 )
	nss? ( dev-libs/nss )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	doc? ( >=app-doc/doxygen-1.4.7 )"

src_compile() {
	econf \
		--docdir="/usr/share/doc/${PF}" \
		$(use_enable doc) \
		$(use_enable gnutls crypto-engine-gnutls) \
		$(use_enable nss crypto-engine-nss)
	emake || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	mv "${D}/usr/share/doc/${PF}/api" "${T}"
	prepalldocs
	mv "${T}/api" "${D}/usr/share/doc/${PF}"
}
