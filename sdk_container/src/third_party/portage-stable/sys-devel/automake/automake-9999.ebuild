# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/automake/automake-9999.ebuild,v 1.7 2013/01/03 18:45:44 vapier Exp $

EAPI="2"
EGIT_REPO_URI="git://git.savannah.gnu.org/${PN}.git
	http://git.savannah.gnu.org/r/${PN}.git"

inherit eutils git-2

DESCRIPTION="Used to generate Makefile.in from Makefile.am"
HOMEPAGE="http://www.gnu.org/software/automake/"
SRC_URI=""

LICENSE="GPL-3"
SLOT="${PV:0:4}"
KEYWORDS=""
IUSE=""

RDEPEND="dev-lang/perl
	>=sys-devel/automake-wrapper-2
	>=sys-devel/autoconf-2.60
	>=sys-apps/texinfo-4.7
	sys-devel/gnuconfig"
DEPEND="${RDEPEND}
	sys-apps/help2man"

src_prepare() {
	sed -i \
		-e "s|: (automake)| v${SLOT}: (automake${SLOT})|" \
		doc/automake.texi doc/automake-history.texi || die
	export WANT_AUTOCONF=2.5
	# Don't try wrapping the autotools this thing runs as it tends
	# to be a bit esoteric, and the script does `set -e` itself.
	./bootstrap
}

src_configure() {
	econf --docdir=/usr/share/doc/${PF}
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
	cd "${D}"/usr/share/info || die
	for x in *.info* ; do
		mv "${x}" "${x/${PN}/${PN}${SLOT}}" || die
	done

	# remove all config.guess and config.sub files replacing them
	# w/a symlink to a specific gnuconfig version
	for x in guess sub ; do
		dosym ../gnuconfig/config.${x} /usr/share/${PN}-${SLOT}/config.${x}
	done
}
