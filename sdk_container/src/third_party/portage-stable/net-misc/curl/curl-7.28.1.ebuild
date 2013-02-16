# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/curl/curl-7.28.1.ebuild,v 1.1 2012/11/20 18:22:58 blueness Exp $

EAPI="4"

inherit autotools eutils prefix

DESCRIPTION="A Client that groks URLs"
HOMEPAGE="http://curl.haxx.se/"
SRC_URI="http://curl.haxx.se/download/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~ppc-aix ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="adns idn ipv6 kerberos ldap metalink +nonblocking rtmp ssh ssl static-libs test threads"
IUSE="${IUSE} curl_ssl_axtls curl_ssl_cyassl curl_ssl_gnutls curl_ssl_nss +curl_ssl_openssl curl_ssl_polarssl"

#lead to lots of false negatives, bug #285669
RESTRICT="test"

RDEPEND="ldap? ( net-nds/openldap )
	ssl? (
		curl_ssl_axtls?  ( net-libs/axtls  app-misc/ca-certificates )
		curl_ssl_cyassl? ( net-libs/cyassl app-misc/ca-certificates )
		curl_ssl_gnutls? (
			|| (
				( >=net-libs/gnutls-3[static-libs?] dev-libs/nettle )
				( =net-libs/gnutls-2.12*[nettle,static-libs?] dev-libs/nettle )
				( =net-libs/gnutls-2.12*[-nettle,static-libs?] dev-libs/libgcrypt[static-libs?] )
			)
			app-misc/ca-certificates
		)
		curl_ssl_openssl? ( dev-libs/openssl[static-libs?] )
		curl_ssl_nss? ( dev-libs/nss app-misc/ca-certificates )
		curl_ssl_polarssl? ( net-libs/polarssl app-misc/ca-certificates )
	)
	idn? ( net-dns/libidn[static-libs?] )
	adns? ( net-dns/c-ares )
	kerberos? ( virtual/krb5 )
	metalink? ( >=media-libs/libmetalink-0.1.0 )
	rtmp? ( media-video/rtmpdump )
	ssh? ( net-libs/libssh2[static-libs?] )
	sys-libs/zlib"

# Do we need to enforce the same ssl backend for curl and rtmpdump? Bug #423303
#	rtmp? (
#		media-video/rtmpdump
#		curl_ssl_gnutls? ( media-video/rtmpdump[gnutls] )
#		curl_ssl_polarssl? ( media-video/rtmpdump[polarssl] )
#		curl_ssl_openssl? ( media-video/rtmpdump[-gnutls,-polarssl,ssl] )
#	)

# ssl providers to be added:
# fbopenssl  $(use_with spnego)

# krb4 http://web.mit.edu/kerberos/www/krb4-end-of-life.html

DEPEND="${RDEPEND}
	virtual/pkgconfig
	test? (
		sys-apps/diffutils
		dev-lang/perl
	)"

# c-ares must be disabled for threads
# only one ssl provider can be enabled
REQUIRED_USE="
	threads? ( !adns )
	ssl? (
		^^ (
			curl_ssl_axtls
			curl_ssl_cyassl
			curl_ssl_gnutls
			curl_ssl_openssl
			curl_ssl_nss
			curl_ssl_polarssl
		)
	)"

DOCS=( CHANGES README docs/FEATURES docs/INTERNALS \
	docs/MANUAL docs/FAQ docs/BUGS docs/CONTRIBUTE)

src_prepare() {
	epatch \
		"${FILESDIR}"/${PN}-7.28.0-prefix.patch \
		"${FILESDIR}"/${PN}-respect-cflags-3.patch \
		"${FILESDIR}"/${PN}-fix-gnutls-nettle.patch
	sed -i '/LD_LIBRARY_PATH=/d' configure.ac || die #382241

	eprefixify curl-config.in
	eautoreconf
}

src_configure() {
	einfo "\033[1;32m**************************************************\033[00m"

	# We make use of the fact that later flags override earlier ones
	# So start with all ssl providers off until proven otherwise
	local myconf=()
	myconf+=( --without-axtls --without-cyassl --without-gnutls --without-nss --without-polarssl --without-ssl )
	myconf+=( --with-ca-bundle="${EPREFIX}"/etc/ssl/certs/ca-certificates.crt )
	if use ssl ; then
		if use curl_ssl_axtls; then
			einfo "SSL provided by axtls"
			einfo "NOTE: axtls is meant for embedded systems and"
			einfo "may not be the best choice as an ssl provider"
			myconf+=( --with-axtls )
		fi
		if use curl_ssl_cyassl; then
			einfo "SSL provided by cyassl"
			einfo "NOTE: cyassl is meant for embedded systems and"
			einfo "may not be the best choice as an ssl provider"
			myconf+=( --with-cyassl )
		fi
		if use curl_ssl_gnutls; then
			einfo "SSL provided by gnutls"
			if has_version ">=net-libs/gnutls-3" || has_version "=net-libs/gnutls-2.12*[nettle]"; then
				einfo "gnutls compiled with dev-libs/nettle"
				myconf+=( --with-gnutls --with-nettle )
			else
				einfo "gnutls compiled with dev-libs/libgcrypt"
				myconf+=( --with-gnutls --without-nettle )
			fi
		fi
		if use curl_ssl_nss; then
			einfo "SSL provided by nss"
			myconf+=( --with-nss )
		fi
		if use curl_ssl_polarssl; then
			einfo "SSL provided by polarssl"
			einfo "NOTE: polarssl is meant for embedded systems and"
			einfo "may not be the best choice as an ssl provider"
			myconf+=( --with-polarssl )
		fi
		if use curl_ssl_openssl; then
			einfo "SSL provided by openssl"
			myconf+=( --with-ssl --without-ca-bundle --with-ca-path="${EPREFIX}"/etc/ssl/certs )
		fi
	else
		einfo "SSL disabled"
	fi
	einfo "\033[1;32m**************************************************\033[00m"

	# These configuration options are organized alphabetically
	# within each category.  This should make it easier if we
	# ever decide to make any of them contingent on USE flags:
	# 1) protocols first.  To see them all do
	# 'grep SUPPORT_PROTOCOLS configure.ac'
	# 2) --enable/disable options second.
	# 'grep -- --enable configure | grep Check | awk '{ print $4 }' | sort
	# 3) --with/without options third.
	# grep -- --with configure | grep Check | awk '{ print $4 }' | sort
	econf \
		--enable-dict \
		--enable-file \
		--enable-ftp \
		--enable-gopher \
		--enable-http \
		--enable-imap \
		$(use_enable ldap) \
		$(use_enable ldap ldaps) \
		--enable-pop3 \
		--enable-rtsp \
		$(use_with ssh libssh2) \
		--enable-smtp \
		--enable-telnet \
		--enable-tftp \
		$(use_enable adns ares) \
		--enable-cookies \
		--enable-hidden-symbols \
		$(use_enable ipv6) \
		--enable-largefile \
		--enable-manual \
		$(use_enable nonblocking) \
		--enable-proxy \
		--disable-soname-bump \
		--disable-sspi \
		$(use_enable static-libs static) \
		$(use_enable threads threaded-resolver) \
		--disable-versioned-symbols \
		--without-darwinssl \
		$(use_with idn libidn) \
		$(use_with kerberos gssapi "${EPREFIX}"/usr) \
		--without-krb4 \
		$(use_with metalink libmetalink)  \
		$(use_with rtmp librtmp) \
		--without-spnego \
		--without-winidn \
		--without-winssl \
		--with-zlib \
		"${myconf[@]}"
}

src_install() {
	default
	find "${ED}" -name '*.la' -delete
	rm -rf "${ED}"/etc/

	# https://sourceforge.net/tracker/index.php?func=detail&aid=1705197&group_id=976&atid=350976
	insinto /usr/share/aclocal
	doins docs/libcurl/libcurl.m4
}
