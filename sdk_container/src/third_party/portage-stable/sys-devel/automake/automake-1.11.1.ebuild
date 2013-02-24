# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/automake/automake-1.11.1.ebuild,v 1.9 2012/01/19 20:55:45 slyfox Exp $

inherit eutils versionator

if [[ ${PV/_beta} == ${PV} ]]; then
	MY_P=${P}
	SRC_URI="mirror://gnu/${PN}/${P}.tar.bz2"
else
	MY_PV="$(get_major_version).$(($(get_version_component_range 2)-1))b"
	MY_P="${PN}-${MY_PV}"

	# Alpha/beta releases are not distributed on the usual mirrors.
	SRC_URI="ftp://alpha.gnu.org/pub/gnu/${PN}/${MY_P}.tar.bz2"
fi

S="${WORKDIR}/${MY_P}"

# Use Gentoo versioning for slotting.
SLOT="${PV:0:4}"

DESCRIPTION="Used to generate Makefile.in from Makefile.am"
HOMEPAGE="http://www.gnu.org/software/automake/"

LICENSE="GPL-2"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE=""

RDEPEND="dev-lang/perl
	>=sys-devel/automake-wrapper-3-r2
	>=sys-devel/autoconf-2.62
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
	econf --docdir=/usr/share/doc/${PF} HELP2MAN=true || die
	emake \
		APIVERSION="${SLOT}" pkgvdatadir="/usr/share/${PN}-${SLOT}" || die

	local x
	for x in aclocal automake; do
		help2man "perl -Ilib ${x}" > doc/${x}-${SLOT}.1
	done
}

src_install() {
	emake DESTDIR="${D}" install \
		APIVERSION="${SLOT}" pkgvdatadir="/usr/share/${PN}-${SLOT}" || die
	dodoc NEWS README THANKS TODO AUTHORS ChangeLog

	rm \
		"${D}"/usr/bin/{aclocal,automake} \
		"${D}"/usr/share/man/man1/{aclocal,automake}.1

	# remove all config.guess and config.sub files replacing them
	# w/a symlink to a specific gnuconfig version
	local x
	for x in guess sub ; do
		dosym ../gnuconfig/config.${x} /usr/share/${PN}-${SLOT}/config.${x}
	done
}
