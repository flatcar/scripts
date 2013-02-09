# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/nas/nas-1.9.2.ebuild,v 1.10 2012/12/03 23:14:19 ulm Exp $

inherit eutils toolchain-funcs

DESCRIPTION="Network Audio System"
HOMEPAGE="http://radscan.com/nas.html"
SRC_URI="mirror://sourceforge/${PN}/${P}.src.tar.gz"

LICENSE="HPND MIT"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd"
IUSE="doc"

RDEPEND="x11-libs/libXt
	x11-libs/libXau
	x11-libs/libXaw
	x11-libs/libX11
	x11-libs/libXres
	x11-libs/libXTrap
	x11-libs/libXp"
DEPEND="${RDEPEND}
	x11-misc/gccmakedep
	x11-misc/imake
	app-text/rman
	x11-proto/xproto"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${P}-asneeded.patch
}

src_compile() {
	xmkmf || die "xmkmf failed"
	touch doc/man/lib/tmp.{_man,man}
	emake \
		MAKE="${MAKE:-gmake}" \
		CDEBUGFLAGS="${CFLAGS}" \
		CXXDEBUFLAGS="${CXXFLAGS}" \
		CC="$(tc-getCC)" \
		CXX="$(tc-getCXX)" \
		AR="$(tc-getAR) clq" \
		AS="$(tc-getAS)" \
		LD="$(tc-getLD)" \
		RANLIB="$(tc-getRANLIB)" World || die "emake World failed"
}

src_install () {
	emake DESTDIR="${D}" install install.man || die "emake install failed"
	dodoc BUILDNOTES FAQ HISTORY README RELEASE TODO

	if use doc; then
		docinto doc
		dodoc doc/{actions,protocol.txt,README}
		insinto /usr/share/doc/${PF}/pdf
		doins doc/pdf/*.pdf
	fi

	mv "${D}"/etc/nas/nasd.conf{.eg,}

	newconfd "${FILESDIR}"/nas.conf.d nas
	newinitd "${FILESDIR}"/nas.init.d nas
}

pkg_postinst() {
	elog "To enable NAS on boot you will have to add it to the"
	elog "default profile, issue the following command as root:"
	elog "# rc-update add nas default"
}
