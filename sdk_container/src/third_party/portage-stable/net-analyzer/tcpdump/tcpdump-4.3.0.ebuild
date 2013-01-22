# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-analyzer/tcpdump/tcpdump-4.3.0.ebuild,v 1.8 2012/09/30 16:39:54 armin76 Exp $

EAPI="4"

AUTOTOOLS_AUTO_DEPEND="no" # Only cross-compiling
inherit flag-o-matic user autotools eutils toolchain-funcs

DESCRIPTION="A Tool for network monitoring and data acquisition"
HOMEPAGE="http://www.tcpdump.org/"
SRC_URI="http://www.tcpdump.org/release/${P}.tar.gz
		http://www.jp.tcpdump.org/release/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux"
IUSE="+chroot smi ssl ipv6 -samba suid test"

RDEPEND="
	net-libs/libpcap
	smi? ( net-libs/libsmi )
	ssl? ( >=dev-libs/openssl-0.9.6m )
"
DEPEND="
	${RDEPEND}
	test? (
		|| ( app-arch/sharutils sys-freebsd/freebsd-ubin )
		dev-lang/perl
	)
"

pkg_setup() {
	if use samba ; then
		ewarn
		ewarn "CAUTION !!! CAUTION !!! CAUTION"
		ewarn
		ewarn "You're about to compile tcpdump with samba printing support"
		ewarn "Upstream tags it as 'possibly-buggy SMB printer'"
		ewarn "So think twice whether this is fine with you"
		ewarn
		ewarn "CAUTION !!! CAUTION !!! CAUTION"
		ewarn
	fi
	enewgroup tcpdump
	enewuser tcpdump -1 -1 -1 tcpdump
}

src_prepare() {
	if tc-is-cross-compiler ; then
		epatch "${FILESDIR}"/${P}-ssl-detect.patch
		eautoreconf
	fi
}

src_configure() {
	# tcpdump needs some optymalization. see bug #108391
	( ! is-flag -O? || is-flag -O0 ) && append-flags -O2

	replace-flags -O[3-9] -O2
	filter-flags -finline-functions

	econf \
		--with-user=tcpdump \
		$(use_with ssl crypto "${EPREFIX}/usr") \
		$(use_with smi) \
		$(use_enable ipv6) \
		$(use_enable samba smb) \
		$(use_with chroot chroot "${EPREFIX}/var/lib/tcpdump")
}

src_test() {
	sed '/^\(espudp1\|eapon1\)/d;' -i tests/TESTLIST
	emake check
}

src_install() {
	dosbin tcpdump
	doman tcpdump.1
	dodoc *.awk
	dodoc CHANGES CREDITS README

	if use chroot; then
		keepdir /var/lib/tcpdump
		fperms 700 /var/lib/tcpdump
		fowners tcpdump:tcpdump /var/lib/tcpdump
	fi
	if use suid; then
		fowners root:tcpdump /usr/sbin/tcpdump
		fperms 4110 /usr/sbin/tcpdump
	fi
}

pkg_postinst() {
	use suid && elog "To let normal users run tcpdump add them into tcpdump group."
}
