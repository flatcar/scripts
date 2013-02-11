# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/xml-security-c/xml-security-c-1.6.1.ebuild,v 1.2 2012/05/04 18:35:52 jdhore Exp $

EAPI="4"

inherit eutils

DESCRIPTION="Apache C++ XML security libraries."
HOMEPAGE="http://santuario.apache.org/"
SRC_URI="mirror://apache/santuario/c-library/${P}.tar.gz"
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug examples nss static-libs xalan"

RDEPEND=">=dev-libs/xerces-c-3.1
	dev-libs/openssl
	nss? ( dev-libs/nss )
	xalan? ( dev-libs/xalan-c )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_prepare() {
	epatch "${FILESDIR}/${PV}-nss-compilation-fix.patch"
}

src_configure() {
	econf \
		--with-openssl \
		$(use_enable static-libs static) \
		$(use_enable debug) \
		$(use_with xalan) \
		$(use_with nss)
}

src_install() {
	DOCS="CHANGELOG.txt NOTICE.txt"
	default
	if use examples ; then
		insinto /usr/share/doc/${PF}/examples
		doins xsec/samples/*.cpp
	fi
}
