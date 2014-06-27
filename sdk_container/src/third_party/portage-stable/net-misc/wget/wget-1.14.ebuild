# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/wget/wget-1.14.ebuild,v 1.14 2014/01/18 05:35:17 vapier Exp $

EAPI="4"

inherit flag-o-matic toolchain-funcs autotools

DESCRIPTION="Network utility to retrieve files from the WWW"
HOMEPAGE="http://www.gnu.org/software/wget/"
SRC_URI="mirror://gnu/wget/${P}.tar.xz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~arm-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="debug gnutls idn ipv6 nls ntlm pcre +ssl static uuid zlib"

LIB_DEPEND="idn? ( net-dns/libidn[static-libs(+)] )
	pcre? ( dev-libs/libpcre[static-libs(+)] )
	ssl? (
		gnutls? ( net-libs/gnutls[static-libs(+)] )
		!gnutls? ( dev-libs/openssl:0[static-libs(+)] )
	)
	uuid? ( sys-apps/util-linux[static-libs(+)] )
	zlib? ( sys-libs/zlib[static-libs(+)] )"
RDEPEND="!static? ( ${LIB_DEPEND//\[static-libs(+)]} )"
DEPEND="${RDEPEND}
	app-arch/xz-utils
	virtual/pkgconfig
	static? ( ${LIB_DEPEND} )
	nls? ( sys-devel/gettext )"

REQUIRED_USE="ntlm? ( !gnutls ssl ) gnutls? ( ssl )"

DOCS=( AUTHORS MAILING-LIST NEWS README doc/sample.wgetrc )

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.13.4-openssl-pkg-config.patch \
		"${FILESDIR}"/${P}-texi2pod.patch
	eautoreconf
}

src_configure() {
	# openssl-0.9.8 now builds with -pthread on the BSD's
	use elibc_FreeBSD && use ssl && append-ldflags -pthread
	# fix compilation on Solaris, we need filio.h for FIONBIO as used in
	# the included gnutls -- force ioctl.h to include this header
	[[ ${CHOST} == *-solaris* ]] && append-flags -DBSD_COMP=1

	# some libraries tests lack configure options :( #432468
	eval export ac_cv_{header_pcre_h,lib_pcre_pcre_compile}=$(usex pcre)
	eval export ac_cv_{header_uuid_uuid_h,lib_uuid_uuid_generate}=$(usex uuid)

	if use static ; then
		append-ldflags -static
		tc-export PKG_CONFIG
		PKG_CONFIG+=" --static"
	fi
	econf \
		--disable-rpath \
		$(use_with ssl ssl $(usex gnutls gnutls openssl)) \
		$(use_enable ssl opie) \
		$(use_enable ssl digest) \
		$(use_enable idn iri) \
		$(use_enable ipv6) \
		$(use_enable nls) \
		$(use_enable ntlm) \
		$(use_enable debug) \
		$(use_with zlib)
}

src_install() {
	default

	sed -i \
		-e "s:/usr/local/etc:${EPREFIX}/etc:g" \
		"${ED}"/etc/wgetrc \
		"${ED}"/usr/share/man/man1/wget.1 \
		"${ED}"/usr/share/info/wget.info
}
