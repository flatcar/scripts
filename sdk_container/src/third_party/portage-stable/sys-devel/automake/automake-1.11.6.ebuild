# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/automake/automake-1.11.6.ebuild,v 1.10 2014/01/17 04:23:15 vapier Exp $

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

S="${WORKDIR}/${MY_P}"

# Use Gentoo versioning for slotting.
SLOT="${PV:0:4}"

DESCRIPTION="Used to generate Makefile.in from Makefile.am"
HOMEPAGE="http://www.gnu.org/software/automake/"

LICENSE="GPL-2"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd"
IUSE=""

RDEPEND="dev-lang/perl
	>=sys-devel/automake-wrapper-9
	>=sys-devel/autoconf-2.62
	sys-devel/gnuconfig"
DEPEND="${RDEPEND}
	sys-apps/help2man"

src_unpack() {
	unpacker_src_unpack
	cd "${S}"
	chmod a+rx tests/*.test
	export WANT_AUTOCONF=2.5
}

src_compile() {
	econf --docdir=/usr/share/doc/${PF} HELP2MAN=true || die
	emake APIVERSION="${SLOT}" pkgvdatadir="/usr/share/${PN}-${SLOT}" || die

	local x
	for x in aclocal automake; do
		help2man "perl -Ilib ${x}" > doc/${x}-${SLOT}.1
	done
}

# slot the info pages.  do this w/out munging the source so we don't have
# to depend on texinfo to regen things.  #464146 (among others)
slot_info_pages() {
	pushd "${D}"/usr/share/info >/dev/null
	rm -f dir

	# Rewrite all the references to other pages.
	# before: * aclocal-invocation: (automake)aclocal Invocation.   Generating aclocal.m4.
	# after:  * aclocal-invocation v1.13: (automake-1.13)aclocal Invocation.   Generating aclocal.m4.
	local p pages=( *.info ) args=()
	for p in "${pages[@]/%.info}" ; do
		args+=(
			-e "/START-INFO-DIR-ENTRY/,/END-INFO-DIR-ENTRY/s|: (${p})| v${SLOT}&|"
			-e "s:(${p}):(${p}-${SLOT}):g"
		)
	done
	sed -i "${args[@]}" * || die

	# Rewrite all the file references, and rename them in the process.
	local f d
	for f in * ; do
		d=${f/.info/-${SLOT}.info}
		mv "${f}" "${d}" || die
		sed -i -e "s:${f}:${d}:g" * || die
	done

	popd >/dev/null
}

src_install() {
	emake DESTDIR="${D}" install \
		APIVERSION="${SLOT}" pkgvdatadir="/usr/share/${PN}-${SLOT}" || die
	slot_info_pages
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
