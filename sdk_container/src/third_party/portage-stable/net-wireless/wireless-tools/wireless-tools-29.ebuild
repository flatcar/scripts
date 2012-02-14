# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/wireless-tools/wireless-tools-29.ebuild,v 1.12 2009/09/12 23:30:12 flameeyes Exp $

inherit toolchain-funcs multilib eutils

# The following works with both pre-releases and releases
MY_P=${PN/-/_}.${PV/_/.}
S=${WORKDIR}/${MY_P/\.pre*/}

DESCRIPTION="A collection of tools to configure IEEE 802.11 wireless LAN cards"
HOMEPAGE="http://www.hpl.hp.com/personal/Jean_Tourrilhes/Linux/Tools.html"
SRC_URI="http://www.hpl.hp.com/personal/Jean_Tourrilhes/Linux/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm hppa ~ia64 ~mips ppc ppc64 sh ~sparc x86"
IUSE="multicall nls"

DEPEND="sys-apps/sed"
RDEPEND=""

src_unpack() {
	unpack ${A}

	epatch "${FILESDIR}/${P}-asneeded.patch"

	sed -i \
		-e "s:^\(CC\) = gcc:\1 = $(tc-getCC):" \
		-e "s:^\(AR\) = ar:\1 = $(tc-getAR):" \
		-e "s:^\(RANLIB\) = ranlib:\1 = $(tc-getRANLIB):" \
		-e "s:^\(CFLAGS=-Os\):#\1:" \
		-e "s:\(@\$(LDCONFIG).*\):#\1:" \
		-e "s:^\(INSTALL_MAN= \$(PREFIX)\)/man/:\1/share/man:" \
		-e "s:^\(INSTALL_LIB= \$(PREFIX)\)/lib/:\1/$(get_libdir)/:" \
		-e '/\$(CC)/s:-Wl,-s\>::' \
		"${S}"/Makefile || die
}

src_compile() {
	emake || die "emake failed"

	if use multicall; then
		emake iwmulticall || die "emake iwmulticall failed"
	fi
}

src_install() {
	make PREFIX="${D}" INSTALL_INC="${D}"/usr/include INSTALL_MAN="${D}"/usr/share/man install \
		|| die "make install failed"

	if use multicall; then
		# 'make install-iwmulticall' will overwrite some of the tools
		# with symlinks - this is intentional (brix)
		make PREFIX="${D}" INSTALL_INC="${D}"/usr/include INSTALL_MAN="${D}"/usr/share/man install-iwmulticall \
			|| die "make install-iwmulticall failed"
	fi

	if use nls; then
		for lang in fr cs; do
			for man in 5 7 8; do
				insinto /usr/share/man/${lang}/man${man}
				doins ${lang}/*.${man}
			done

			[[ -f README.${lang} ]] && dodoc README.${lang}
		done
	fi

	dodoc CHANGELOG.h DISTRIBUTIONS.txt HOTPLUG.txt IFRENAME-VS-XXX.txt PCMCIA.txt README
}
