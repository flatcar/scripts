# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/automake/automake-1.12.6.ebuild,v 1.3 2013/01/03 18:45:44 vapier Exp $

inherit eutils versionator unpacker

if [[ ${PV/_beta} == ${PV} ]]; then
	MY_P=${P}
	SRC_URI="mirror://gnu/${PN}/${P}.tar.xz
		ftp://alpha.gnu.org/pub/gnu/${PN}/${MY_P}.tar.xz"
else
	MY_PV="$(get_major_version).$(($(get_version_component_range 2)-1))b"
	MY_P="${PN}-${MY_PV}"

	# Alpha/beta releases are not distributed on the usual mirrors.
	SRC_URI="ftp://alpha.gnu.org/pub/gnu/${PN}/${MY_P}.tar.xz"
fi

DESCRIPTION="Used to generate Makefile.in from Makefile.am"
HOMEPAGE="http://www.gnu.org/software/automake/"

LICENSE="GPL-2"
# Use Gentoo versioning for slotting.
SLOT="${PV:0:4}"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~sparc-fbsd ~x86-fbsd"
IUSE=""

RDEPEND="dev-lang/perl
	>=sys-devel/automake-wrapper-7
	>=sys-devel/autoconf-2.62
	>=sys-apps/texinfo-4.7
	sys-devel/gnuconfig"
DEPEND="${RDEPEND}
	sys-apps/help2man"

S="${WORKDIR}/${MY_P}"

src_unpack() {
	unpacker_src_unpack
	cd "${S}"
	sed -i \
		-e "s|: (automake)| v${SLOT}: (automake${SLOT})|" \
		doc/automake.texi doc/automake-history.texi || die
	local f
	for f in doc/automake{,-history}.{texi,info*} ; do
		mv ${f} ${f%.*}${SLOT}.${f#*.} || die
	done
	touch -r configure doc/*.{texi,info}*
	sed -i -r \
		-e "s:(automake|automake-history)(.info|.texi):\1${SLOT}\2:g" \
		Makefile.in || die
	export WANT_AUTOCONF=2.5
}

src_compile() {
	econf --docdir=/usr/share/doc/${PF} HELP2MAN=true || die
	emake APIVERSION="${SLOT}" pkgvdatadir="/usr/share/${PN}-${SLOT}" || die
}

src_install() {
	emake DESTDIR="${D}" install \
		APIVERSION="${SLOT}" pkgvdatadir="/usr/share/${PN}-${SLOT}" || die
	rm "${D}"/usr/share/aclocal/README || die
	rmdir "${D}"/usr/share/aclocal || die
	dodoc AUTHORS ChangeLog NEWS README THANKS

	rm \
		"${D}"/usr/bin/{aclocal,automake} \
		"${D}"/usr/share/man/man1/{aclocal,automake}.1 || die

	# remove all config.guess and config.sub files replacing them
	# w/a symlink to a specific gnuconfig version
	local x
	for x in guess sub ; do
		dosym ../gnuconfig/config.${x} /usr/share/${PN}-${SLOT}/config.${x}
	done
}
