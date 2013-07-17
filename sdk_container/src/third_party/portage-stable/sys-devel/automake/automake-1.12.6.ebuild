# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/automake/automake-1.12.6.ebuild,v 1.17 2013/04/17 17:53:52 aballier Exp $

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
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd"
IUSE=""

RDEPEND="dev-lang/perl
	>=sys-devel/automake-wrapper-7
	>=sys-devel/autoconf-2.62
	sys-devel/gnuconfig"
DEPEND="${RDEPEND}
	sys-apps/help2man"

S="${WORKDIR}/${MY_P}"

src_unpack() {
	unpacker_src_unpack
	cd "${S}"
	export WANT_AUTOCONF=2.5
}

src_compile() {
	econf --docdir=/usr/share/doc/${PF} HELP2MAN=true || die
	emake APIVERSION="${SLOT}" pkgvdatadir="/usr/share/${PN}-${SLOT}" || die
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
