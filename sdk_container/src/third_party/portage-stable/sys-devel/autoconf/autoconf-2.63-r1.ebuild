# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/autoconf/autoconf-2.63-r1.ebuild,v 1.4 2013/04/04 22:59:16 vapier Exp $

inherit eutils

DESCRIPTION="Used to create autoconfiguration files"
HOMEPAGE="http://www.gnu.org/software/autoconf/autoconf.html"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT=$(usex multislot "${PV}" "2.5")
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc ~sparc-fbsd x86 ~x86-fbsd"
IUSE="emacs multislot"

DEPEND=">=sys-devel/m4-1.4.6
	dev-lang/perl"
RDEPEND="${DEPEND}
	>=sys-devel/autoconf-wrapper-6"
PDEPEND="emacs? ( app-emacs/autoconf-mode )"

src_unpack() {
	unpack ${A}
	cd "${S}"
	use multislot && find -name Makefile.in -exec sed -i '/^pkgdatadir/s:$:-@VERSION@:' {} +
	epatch "${FILESDIR}"/${P}-sh.patch #264303
}

src_compile() {
	# Disable Emacs in the build system since it is in a separate package.
	export EMACS=no
	econf --program-suffix="-${PV}" || die
	# econf updates config.{sub,guess} which forces the manpages
	# to be regenerated which we dont want to do #146621
	touch man/*.1
	emake || die
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS BUGS NEWS README TODO THANKS \
		ChangeLog ChangeLog.0 ChangeLog.1 ChangeLog.2

	if use multislot ; then
		local f
		for f in "${D}"/usr/share/info/*.info* ; do
			mv "${f}" "${f/.info/-${SLOT}.info}" || die
		done
	fi
}
