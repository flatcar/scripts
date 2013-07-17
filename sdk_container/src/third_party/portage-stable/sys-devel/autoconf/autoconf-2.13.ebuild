# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/autoconf/autoconf-2.13.ebuild,v 1.22 2013/01/28 14:34:28 aballier Exp $

inherit eutils

DESCRIPTION="Used to create autoconfiguration files"
HOMEPAGE="http://www.gnu.org/software/autoconf/autoconf.html"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="${PV:0:3}"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd"
IUSE="userland_BSD"

DEPEND=">=sys-apps/texinfo-4.3
	sys-devel/autoconf-wrapper
	=sys-devel/m4-1.4*
	dev-lang/perl"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${P}-gentoo.patch
	epatch "${FILESDIR}"/${P}-destdir.patch
	epatch "${FILESDIR}"/${P}-test-fixes.patch #146592
	touch configure # make sure configure is newer than configure.in

	rm -f standards.{texi,info} # binutils installs this infopage

	sed -i \
		-e 's|\* Autoconf:|\* Autoconf v2.1:|' \
		-e '/START-INFO-DIR-ENTRY/ i INFO-DIR-SECTION GNU programming tools' \
		autoconf.texi \
		|| die "sed failed"
}

src_compile() {
	# need to include --exec-prefix and --bindir or our
	# DESTDIR patch will trigger sandbox hate :(
	#
	# need to force locale to C to avoid bugs in the old
	# configure script breaking the install paths #351982
	#
	# force to `awk` so that we don't encode another awk that
	# happens to currently be installed, but might later be
	# uninstalled (like mawk).  same for m4.
	local prepend=""
	use userland_BSD && prepend="g"
	ac_cv_path_M4="${prepend}m4" \
	ac_cv_prog_AWK="${prepend}awk" \
	LC_ALL=C \
	econf \
		--exec-prefix=/usr \
		--bindir=/usr/bin \
		--program-suffix="-${PV}" \
		|| die
	emake || die
}

src_install() {
	emake install DESTDIR="${D}" || die

	dodoc AUTHORS NEWS README TODO ChangeLog ChangeLog.0 ChangeLog.1

	mv "${D}"/usr/share/info/autoconf{,-${PV}}.info
}
