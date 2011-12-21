# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/groff/groff-1.20.1-r3.ebuild,v 1.9 2011/02/24 22:13:39 xarthisius Exp $

inherit autotools eutils toolchain-funcs

DESCRIPTION="Text formatter used for man pages"
HOMEPAGE="http://www.gnu.org/software/groff/groff.html"
SRC_URI="mirror://gnu/groff/${P}.tar.gz
	linguas_ja? ( mirror://gentoo/${P}-r2-japanese.patch.bz2 )"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="examples X linguas_ja"

DEPEND=">=sys-apps/texinfo-4.7-r1
	X? (
		x11-libs/libX11
		x11-libs/libXt
		x11-libs/libXmu
		x11-libs/libXaw
		x11-libs/libSM
		x11-libs/libICE
	)"

src_unpack() {
	unpack ${A}
	cd "${S}"

	epatch "${FILESDIR}"/${PN}-1.19.2-man-unicode-dashes.patch #16108 #17580 #121502
	epatch "${FILESDIR}"/${P}-tmac-ec.patch #263524
	epatch "${FILESDIR}"/${P}-Thtml-mem-leak.patch #294045
	epatch "${FILESDIR}"/${P}-double-frees-mem-leaks.patch #294045
	epatch "${FILESDIR}"/${PN}-1.20.1-pdfmark-parallel.patch

	# put the docs in the Gentoo-specific spot
	sed -i \
		-e '/^docdir=/s/=.*/=@docdir@/' \
		Makefile.in \
		|| die "sed failed"

	# Make sure we can cross-compile this puppy
	if tc-is-cross-compiler ; then
		sed -i \
			-e '/^GROFFBIN=/s:=.*:=/usr/bin/groff:' \
			-e '/^TROFFBIN=/s:=.*:=/usr/bin/troff:' \
			-e '/^GROFF_BIN_PATH=/s:=.*:=:' \
			-e '/^GROFF_BIN_DIR=/s:=.*:=:' \
			contrib/*/Makefile.sub \
			doc/Makefile.in \
			doc/Makefile.sub || die "cross-compile sed failed"
	fi

	cat <<-EOF >> tmac/mdoc.local
	.ds volume-operating-system Gentoo
	.ds operating-system Gentoo/${KERNEL}
	.ds default-operating-system Gentoo/${KERNEL}
	EOF

	if use linguas_ja ; then
		epatch "${WORKDIR}"/${P}-r2-japanese.patch #255292
		eautoconf
		eautoheader
	fi
}

src_compile() {
	# Fix problems with not finding g++
#	tc-export CC CXX
	econf \
		--with-appresdir=/usr/share/X11/app-defaults \
		--docdir=/usr/share/doc/${PF} \
		$(use_with X x) \
		$(use linguas_ja && echo --enable-japanese)
	emake || die
}

src_install() {
	emake install DESTDIR="${D}" || die

	# The following links are required for man #123674
	dosym eqn /usr/bin/geqn
	dosym tbl /usr/bin/gtbl

	dodoc BUG-REPORT ChangeLog MORE.STUFF NEWS \
		PROBLEMS PROJECTS README REVISION TODO VERSION

	if ! use examples ; then
		rm -rf "${D}"/usr/share/doc/${PF}/examples
	fi
}
