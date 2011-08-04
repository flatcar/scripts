# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/wget/wget-1.12-r2.ebuild,v 1.8 2010/09/19 17:50:58 armin76 Exp $

EAPI="2"

inherit eutils flag-o-matic

DESCRIPTION="Network utility to retrieve files from the WWW"
HOMEPAGE="http://www.gnu.org/software/wget/"
SRC_URI="mirror://gnu/wget/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="debug idn ipv6 nls ntlm +ssl static"

RDEPEND="idn? ( net-dns/libidn )
	ssl? ( >=dev-libs/openssl-0.9.6b )"
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )"

pkg_setup() {
	if ! use ssl && use ntlm ; then
		elog "USE=ntlm requires USE=ssl, so disabling ntlm support due to USE=-ssl"
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.12-linking.patch
	epatch "${FILESDIR}"/${PN}-1.12-sni.patch #301312
	epatch "${FILESDIR}"/${P}-debug-tests.patch #286173
	epatch "${FILESDIR}"/${P}-CVE-2010-2252.patch #329941
}

src_configure() {
	# openssl-0.9.8 now builds with -pthread on the BSD's
	use elibc_FreeBSD && use ssl && append-ldflags -pthread

	use static && append-ldflags -static
	econf \
		--disable-rpath \
		$(use_with ssl) $(use_enable ssl opie) $(use_enable ssl digest) \
		$(use_enable idn iri) \
		$(use_enable ipv6) \
		$(use_enable nls) \
		$(use ssl && use_enable ntlm) \
		$(use_enable debug)
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog* MAILING-LIST NEWS README
	dodoc doc/sample.wgetrc

	use ipv6 && cat "${FILESDIR}"/wgetrc-ipv6 >> "${D}"/etc/wgetrc

	sed -i \
		-e 's:/usr/local/etc:/etc:g' \
		"${D}"/etc/wgetrc \
		"${D}"/usr/share/man/man1/wget.1 \
		"${D}"/usr/share/info/wget.info
}

pkg_preinst() {
	ewarn "The /etc/wget/wgetrc file has been relocated to /etc/wgetrc"
	if [[ -e ${ROOT}/etc/wget/wgetrc ]] ; then
		if [[ -e ${ROOT}/etc/wgetrc ]] ; then
			ewarn "You have both /etc/wget/wgetrc and /etc/wgetrc ... you should delete the former"
		else
			einfo "Moving /etc/wget/wgetrc to /etc/wgetrc for you"
			mv "${ROOT}"/etc/wget/wgetrc "${ROOT}"/etc/wgetrc
			rmdir "${ROOT}"/etc/wget 2>/dev/null
		fi
	fi
}
