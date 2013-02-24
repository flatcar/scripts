# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/automake/automake-1.10.3.ebuild,v 1.9 2012/05/09 15:38:15 aballier Exp $

inherit eutils

DESCRIPTION="Used to generate Makefile.in from Makefile.am"
HOMEPAGE="http://www.gnu.org/software/automake/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="${PV:0:4}"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd"
IUSE=""

RDEPEND="dev-lang/perl
	>=sys-devel/automake-wrapper-2
	>=sys-devel/autoconf-2.60
	>=sys-apps/texinfo-4.7
	sys-devel/gnuconfig"
DEPEND="${RDEPEND}
	sys-apps/help2man"

src_unpack() {
	unpack ${A}
	cd "${S}"
	chmod a+rx tests/*.test
	sed -i \
		-e "s|: (automake)| v${SLOT}: (automake${SLOT})|" \
		doc/automake.texi || die "sed failed"
	mv doc/automake{,${SLOT}}.texi
	sed -i \
		-e "s:automake.info:automake${SLOT}.info:" \
		-e "s:automake.texi:automake${SLOT}.texi:" \
		doc/Makefile.in || die "sed on Makefile.in failed"
	export WANT_AUTOCONF=2.5
}

src_compile() {
	econf --docdir=/usr/share/doc/${PF} || die
	emake || die
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc NEWS README THANKS TODO AUTHORS ChangeLog

	# SLOT the docs and junk
	local x
	for x in aclocal automake ; do
		help2man "perl -Ilib ${x}" > ${x}-${SLOT}.1
		doman ${x}-${SLOT}.1
		rm -f "${D}"/usr/bin/${x}
	done

	# remove all config.guess and config.sub files replacing them
	# w/a symlink to a specific gnuconfig version
	for x in guess sub ; do
		dosym ../gnuconfig/config.${x} /usr/share/${PN}-${SLOT}/config.${x}
	done
}
