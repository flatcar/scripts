# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-libs/neon/neon-0.29.6.ebuild,v 1.8 2011/07/20 22:14:39 halcy0n Exp $

EAPI="3"

inherit autotools libtool versionator

DESCRIPTION="HTTP and WebDAV client library"
HOMEPAGE="http://www.webdav.org/neon/"
SRC_URI="http://www.webdav.org/neon/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~sparc-fbsd ~x86-fbsd ~x86-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="doc expat gnutls kerberos libproxy nls pkcs11 ssl static-libs zlib"
IUSE_LINGUAS="cs de fr ja nn pl ru tr zh_CN"
for lingua in ${IUSE_LINGUAS}; do
	IUSE+=" linguas_${lingua}"
done
unset lingua
RESTRICT="test"

RDEPEND="expat? ( dev-libs/expat )
	!expat? ( dev-libs/libxml2 )
	gnutls? (
		app-misc/ca-certificates
		>=net-libs/gnutls-2.0
		pkcs11? ( dev-libs/pakchois )
	)
	!gnutls? ( ssl? (
		>=dev-libs/openssl-0.9.6f
		pkcs11? ( dev-libs/pakchois )
	) )
	kerberos? ( virtual/krb5 )
	libproxy? ( net-libs/libproxy )
	nls? ( virtual/libintl )
	zlib? ( sys-libs/zlib )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_prepare() {
	local lingua linguas
	for lingua in ${IUSE_LINGUAS}; do
		use linguas_${lingua} && linguas+=" ${lingua}"
	done
	sed -i -e "s/ALL_LINGUAS=.*/ALL_LINGUAS=\"${linguas}\"/g" configure.in

	AT_M4DIR="macros" eautoreconf

	elibtoolize
}

src_configure() {
	local myconf

	if has_version sys-libs/glibc; then
		einfo "Enabling SSL library thread-safety using POSIX threads..."
		myconf+=" --enable-threadsafe-ssl=posix"
	fi

	if use expat; then
		myconf+=" --with-expat"
	else
		myconf+=" --with-libxml2"
	fi

	if use gnutls; then
		myconf+=" --with-ssl=gnutls --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt"
	elif use ssl; then
		myconf+=" --with-ssl=openssl"
	fi

	econf \
		--enable-shared \
		$(use_with kerberos gssapi) \
		$(use_with libproxy) \
		$(use_enable nls) \
		$(use_with pkcs11 pakchois) \
		$(use_enable static-libs static) \
		$(use_with zlib) \
		${myconf}
}

src_install() {
	emake DESTDIR="${D}" install-lib install-headers install-config install-nls || die "emake install failed"

	find "${ED}" -name "*.la" -print0 | xargs -0 rm -f

	if use doc; then
		emake DESTDIR="${D}" install-docs || die "emake install-docs failed"
	fi

	dodoc AUTHORS BUGS NEWS README THANKS TODO
	doman doc/man/*.[1-8]
}

pkg_postinst() {
	ewarn "Neon has a policy of breaking API across minor versions, this means"
	ewarn "that any package that links against Neon may be broken after"
	ewarn "updating. They will remain broken until they are ported to the"
	ewarn "new API. You can downgrade Neon to the previous version by doing:"
	ewarn
	ewarn "  emerge --oneshot '<${CATEGORY}/${PN}-$(get_version_component_range 1-2 ${PV})'"
	ewarn
	ewarn "You may also have to downgrade any package that has not been"
	ewarn "ported to the new API yet."
}
