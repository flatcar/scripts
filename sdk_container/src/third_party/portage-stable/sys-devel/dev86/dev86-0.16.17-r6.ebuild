# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/dev86/dev86-0.16.17-r6.ebuild,v 1.7 2011/04/20 20:23:45 jlec Exp $

inherit eutils

DESCRIPTION="Bruce's C compiler - Simple C compiler to generate 8086 code"
HOMEPAGE="http://www.debath.co.uk/"
SRC_URI="http://www.debath.co.uk/dev86/Dev86src-${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND="sys-devel/bin86"
DEPEND="${RDEPEND}
	dev-util/gperf"

src_unpack() {
	unpack ${A}
	# elksemu doesn't compile under amd64
	if use amd64; then
		einfo "Not compiling elksemu on amd64"
		sed -i.orig \
			-e 's,alt-libs elksemu,alt-libs,' \
			-e 's,install-lib install-emu,install-lib,' \
			"${S}"/makefile.in
	fi
	cd "${S}"
	epatch "${FILESDIR}"/dev86-pic.patch
	epatch "${FILESDIR}"/${P}-fortify.patch
	epatch "${FILESDIR}"/${P}-make382.patch
	sed -i \
		-e "s:-O2 -g:${CFLAGS}:" \
		-e '/INEXE=/s:-s::' \
		makefile.in
	sed -i -e '/INSTALL_OPTS=/s:-s::' bin86/Makefile
	sed -i -e '/install -m 755 -s/s:-s::' dis88/Makefile
}

src_compile() {
	# Don't mess with CPPFLAGS as they tend to break compilation
	# (bug #343655).
	CPPFLAGS=""

	emake -j1 DIST="${D}" CC="$(tc-getCC)" || die

	export PATH=${S}/bin:${PATH}
	cd bin
	ln -s ncc bcc
	cd ..
	cd bootblocks
	ln -s ../bcc/version.h .
	emake DIST="${D}" || die
}

src_install() {
	emake -j1 install-all DIST="${D}" || die
	dobin bootblocks/makeboot || die
	# remove all the stuff supplied by bin86
	cd "${D}"
	rm usr/bin/{as,ld,nm,objdump,size}86 || die
	rm usr/man/man1/{as,ld}86.1 || die
	dodir /usr/share/man
	mv usr/man usr/share/ || die
}
