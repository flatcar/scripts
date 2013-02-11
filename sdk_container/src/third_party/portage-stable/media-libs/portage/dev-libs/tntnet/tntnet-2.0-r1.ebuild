# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/tntnet/tntnet-2.0-r1.ebuild,v 1.4 2012/06/04 16:38:22 idl0r Exp $

EAPI="3"

inherit autotools eutils

DESCRIPTION="Modular, multithreaded webapplicationserver extensible with C++"
HOMEPAGE="http://www.tntnet.org/index.hms"
SRC_URI="http://www.tntnet.org/download/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~sparc ~x86"
IUSE="cgi doc examples gnutls server sdk ssl"

RDEPEND="=dev-libs/cxxtools-2.0*
	sys-libs/zlib[minizip]
	ssl? (
		gnutls? (
			>=net-libs/gnutls-1.2.0
			dev-libs/libgcrypt
		)
		!gnutls? ( dev-libs/openssl )
	)"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	examples? ( app-arch/zip )"

src_prepare() {
	# Both fixed in the next release
	epatch "${FILESDIR}/${P}-as-needed.patch"
	epatch "${FILESDIR}/${P}-gnutls.patch"
	epatch "${FILESDIR}"/${P}-zlib-minizip.patch
	rm framework/common/{ioapi,unzip}.[ch] || die

	eautoreconf

	sed -i -e 's:@localstatedir@:/var:' etc/tntnet/tntnet.conf.in || die
}

src_configure() {
	local myconf=""

	# Prefer gnutls above SSL
	if use gnutls; then
		einfo "Using gnutls for ssl support."
		myconf="${myconf} --with-ssl=gnutls"
	elif use ssl; then
		einfo "Using openssl for ssl support."
		myconf="${myconf} --with-ssl=openssl"
	else
		myconf="${myconf} --with-ssl=no"
	fi

	# demos/examples depend upon sdk
	if use examples && ! use sdk; then
		myconf="${myconf} --with-sdk"
	fi

	econf \
		$(use_with examples demos) \
		$(use_with sdk) \
		$(use_with cgi) \
		$(use_with server) \
		${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die

	dodoc AUTHORS ChangeLog README TODO
	if use doc; then
		dodoc doc/*.pdf || die
	fi

	if use examples; then
		cd "${S}/sdk/demos"
		emake clean
		rm -rf .deps */.deps .libs */.libs
		cd "${S}"

		insinto /usr/share/doc/${PF}/examples
		doins -r sdk/demos/* || die
	fi

	if use server; then
		rm -f "${D}/etc/init.d/tntnet"
		newinitd "${FILESDIR}/tntnet.initd" tntnet
	fi
}
