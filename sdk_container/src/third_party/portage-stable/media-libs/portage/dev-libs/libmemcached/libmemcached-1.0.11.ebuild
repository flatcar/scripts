# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libmemcached/libmemcached-1.0.11.ebuild,v 1.1 2012/10/09 08:43:21 patrick Exp $

EAPI="3"

inherit eutils multilib

DESCRIPTION="a C client library to the memcached server"
HOMEPAGE="http://libmemcached.org/libMemcached.html"
SRC_URI="http://launchpad.net/${PN}/1.0/${PV}/+download/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sh ~sparc ~x86 ~sparc-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE="debug doc hsieh +libevent sasl static-libs tcmalloc"

DEPEND="net-misc/memcached
		virtual/perl-PodParser
		doc? ( dev-python/sphinx )
		libevent? ( dev-libs/libevent )
		tcmalloc? ( dev-util/google-perftools )
		sasl? ( virtual/gsasl )"
RDEPEND="${DEPEND}"

src_prepare() {
	# These tests freezes for me
	sed -i \
		-e "/connectionpool/d" \
		-e "/lp:583031/d" \
		tests/${P%.*}/mem_functions.cc || die
}

src_configure() {
	econf \
		--disable-dtrace \
		--disable-libinnodb \
		$(use_enable debug assert) \
		$(use_with debug debug) \
		$(use_enable hsieh hsieh_hash) \
		$(use_enable libevent libevent) \
		$(use_enable tcmalloc tcmalloc) \
		$(use_with sasl libsasl-prefix) \
		$(use_with sasl libsasl2-prefix) \
		$(use_enable static-libs static)
}

src_compile() {
	emake || die

	if use doc; then
		emake html-local || die
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die "Install failed"

	use static-libs || rm -f "${D}"/usr/$(get_libdir)/lib*.la

	dodoc AUTHORS ChangeLog README THANKS TODO
	# remove manpage to avoid collision, see bug #299330
	rm -f "${D}"/usr/share/man/man1/memdump.* || die "Install failed"
	newman docs/man/memdump.1 memcached_memdump.1
	if use doc; then
		dohtml -r docs/html/* || die
	fi
}
