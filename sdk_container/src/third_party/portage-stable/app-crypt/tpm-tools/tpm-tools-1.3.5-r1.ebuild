# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-crypt/tpm-tools/tpm-tools-1.3.5-r1.ebuild,v 1.1 2011/03/31 22:19:40 flameeyes Exp $

EAPI=4
inherit autotools eutils flag-o-matic

DESCRIPTION="TrouSerS' support tools for the Trusted Platform Modules"
HOMEPAGE="http://trousers.sourceforge.net"
SRC_URI="mirror://sourceforge/trousers/${P}.tar.gz"
LICENSE="CPL-1.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="nls pkcs11 debug"

COMMON_DEPEND="
	>=app-crypt/trousers-0.3.0
	dev-libs/openssl
	pkcs11? ( dev-libs/opencryptoki )
	"
RDEPEND="${COMMON_DEPEND}
	nls? ( virtual/libintl )"
DEPEND="${COMMON_DEPEND}
	nls? ( sys-devel/gettext )"

src_prepare() {
	sed -i -e "s/-Werror //" configure.in || die "Sed failed"
	epatch "${FILESDIR}"/${PN}-1.3.1-gold.patch

	eautoreconf
}

src_configure() {
	local myconf="$(use_enable nls)"

	# don't use --enable-pkcs11-support, configure is a mess.
	use pkcs11 || myconf+=" --disable-pkcs11-support"

	use debug && append-flags -DDEBUG || append-flags -DNDEBUG

	econf ${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc README
}
